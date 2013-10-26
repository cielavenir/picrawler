#coding:utf-8

#Picrawler under CC0
#Picrawler::Tinami module
#!!! Very experimental. Too many modes... !!!

# type[]=X X->1=illust,2=comic,3=model,4=novel,5=cosplay

=begin
POST /view/ID HTTP/1.1
Host: www.tinami.com
User-Agent: Mozilla/5.0
Referer: http://www.tinami.com/view/ID
Cookie: ***
Content-Type: application/x-www-form-urlencoded
Content-Length: ***

action_view_original=true&cont_id=ID&ethna_csrf=***
=end

class Picrawler::Tinami
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","tag"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["www.tinami.com","/","vid"]) && @agent.cookie_jar.jar.exists_rec?(["www.tinami.com","/","rem2"])
				unless @agent.cookie_jar.jar["www.tinami.com"]["/"]["vid"].expired? || @agent.cookie_jar.jar["www.tinami.com"]["/"]["rem2"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.tinami.com/login').forms[1]
		form.username = user
		form.password = pass
		#form.checkbox_with("remember_me").check
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
		@type=1
		ret=member_next
		if ret then @notifier.call 'Browsing http://www.tinami.com/search/list?sort=new&type[]=1&prof_id='+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://www.tinami.com/search/list?sort=new&type[]=1&prof_id='+@arg+'&offset='+(@page*20).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/id="next-page"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/view/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		@page+=1
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		@type=1
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.tinami.com/search/list?sort=new&type[]=1&keyword='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://www.tinami.com/search/list?sort=new&type[]=1&keyword='+@arg.uriEncode+'&offset='+(@page*20).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/id="next-page"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/view/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		@page+=1
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> ID
			case @type
				when 1
					if @filter.include?(e)
						if @fast then @seek_end=true end
					else
						@agent.get('http://www.tinami.com/view/'+e, [], 'http://www.tinami.com/') #2.1 syntax
						sleep(1)
						forms = @agent.page.forms
						if forms.length > 2
							form=forms[2]
							body=@agent.submit(form).body
							sleep(1)
							if body=~/(http\:\/\/img.tinami.com\/illust\d*\/img\/\d+\/[0-9a-f]+\.(jpeg|jpg|png|gif))/
								ext=$2
								@agent.get($1, [], 'http://www.tinami.com/') #2.1 syntax
								@enter_critical.call
								@agent.page.save_as(e+"."+ext)
								@exit_critical.call
								sleep(@sleep)
							else
								raise "[Programmer's fault] cannot parse HTML:\n"+body
							end
						end
					end
				else
					raise "Type "+@type.to_s+" not implemented!"
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
