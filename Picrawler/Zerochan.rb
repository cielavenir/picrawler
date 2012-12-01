#coding:utf-8

#Picrawler under CC0
#Picrawler::Zerochan module

class Picrawler::Zerochan
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
	end

	def list() return ["member","tag"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["zerochan.net","/","z_hash"])
				unless @agent.cookie_jar.jar["zerochan.net"]["/"]["z_hash"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.zerochan.net/login').form_with(:action=>"/login")
		form.field_with(:name=>"name").value = user
		form.password = pass
		if @agent.submit(form,form.buttons.first).body.resolve =~ /Logout/ #lol?
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def setup(options={})
		@arg=options[:arg]||raise
		@bookmark=options[:bookmark]||0
		@fast=options[:fast]
		@filter=options[:filter]||[]
		@page=options[:start] ? options[:start]-1 : 0
		@stop=options[:stop]||-1
		@additional=options[:additional]||''
		@seek_end=false
	end

	def member_first(options={})
		setup(options)
		ret=member_next
		if ret then @notifier.call 'Browsing http://www.zerochan.net/user/'+@arg+'?s=id'+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.zerochan.net/user/'+@arg.uriEncode+'?s=id&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		body=@agent.page.body.resolve.split("<ul id=\"thumbs2\">")[1]
		array=body.split("</li>")
		#array.shift
		array.each{|e|
			bookmark=0
			if e=~/<span>(\d+) Fav<\/span>/m
				bookmark=$1.to_i
			end

			#if e=~/src=\"http\:\/\/s[0-9a-z]+\.zerochan\.net\/240\/([0-9a-z\/]+)\.(jpeg|jpg|png|gif)/m
			if e=~/src=\"http\:\/\/s[0-9a-z]+\.zerochan\.net\/([^"]+)\.240\.(\d+)\.(jpeg|jpg|png|gif)"/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.full.'+$2+'.'+$3,$2+'.'+$3])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.zerochan.net/'+@arg+'?s=id'+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.zerochan.net/'+@arg.uriEncode+'?s=id&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		body=@agent.page.body.resolve.split("<ul id=\"thumbs2\">")[1]
		array=body.split("</li>")
		#array.shift
		array.each{|e|
			bookmark=0
			if e=~/<span>(\d+) Fav<\/span>/m
				bookmark=$1.to_i
			end

			#if e=~/src=\"http\:\/\/s[0-9a-z]+\.zerochan\.net\/240\/([0-9a-z\/]+)\.(jpeg|jpg|png|gif)/m
			if e=~/src=\"http\:\/\/s[0-9a-z]+\.zerochan\.net\/([^"]+)\.240\.(\d+)\.(jpeg|jpg|png|gif)"/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.full.'+$2+'.'+$3,$2+'.'+$3])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> fullname, e[1] -> savename
			if @filter.include?(File.basename(e[1],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get("http://static.zerochan.net/"+e[0], [], 'http://www.zerochan.net/') #2.1 syntax
				@agent.page.save_as(e[1]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
