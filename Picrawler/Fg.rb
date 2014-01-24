#coding:utf-8

#Picrawler under CC0
#Picrawler::Fg module
#bookmark isn't implemented.

class Picrawler::Fg
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","search"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.fetch_nested(*["www.fg-site.net","/","wordpress_logged_in_0ec92a783201088155448925f5e07044"])
				unless @agent.cookie_jar.jar["www.fg-site.net"]["/"]["wordpress_logged_in_0ec92a783201088155448925f5e07044"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.fg-site.net/').form_with(:action=>"http://www.fg-site.net/wp-login.php?redirect_to=%2F")
		form.field_with("log").value = user
		form.field_with("pwd").value = pass
		form.checkbox_with("rememberme").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
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
		if ret then @notifier.call 'Browsing http://www.fg-site.net/members/'+@arg+"/gallery\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.fg-site.net/members/'+@arg+'/gallery?page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/archives/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/.+?(http\:\/\/www\.fg-site\.net\/wp-content\/uploads\/[0-9]+\/[0-9]+\/([0-9]+)-image[0-9]+)-[0-9x]+(\.(jpeg|jpg|png|gif))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename,ext = $1,$2,$3
				@content.push([filename+ext,url+ext])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def search_first(options={})
		setup(options)
		ret=search_next
		if ret then @notifier.call 'Browsing http://www.fg-site.net/?s='+@arg+"/\n" end
		return ret
	end

	def search_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.fg-site.net/?s='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/archives/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/.+?(http\:\/\/www\.fg-site\.net\/wp-content\/uploads\/[0-9]+\/[0-9]+\/([0-9]+)-image[0-9]+)-[0-9x]+(\.(jpeg|jpg|png|gif))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename,ext = $1,$2,$3
				@content.push([filename+ext,url+ext])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			e[0]=~/^([0-9]+)/
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.fg-site.net/') #2.1 syntax
				@enter_critical.call
				@agent.page.save_as(e[0])
				@exit_critical.call
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
