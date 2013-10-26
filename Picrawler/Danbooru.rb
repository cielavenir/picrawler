#coding:utf-8

#Picrawler under CC0
#Picrawler::Danbooru module

class Picrawler::Danbooru
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
			if @agent.cookie_jar.jar.exists_rec?(["danbooru.donmai.us","/","Danbooru"])
				unless @agent.cookie_jar.jar["danbooru.donmai.us"]["/"]["Danbooru"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://danbooru.donmai.us/user/login').forms.first
		form.field_with("user[name]").value = user
		form.field_with("user[password]").value = pass
		#form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /logged in/
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
		@arg="user:"+@arg
		ret=tag_next
		if ret then @notifier.call 'Browsing http://danbooru.donmai.us/post?tags=user:'+@arg+"\n" end
		return ret
	end

	def tag_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://danbooru.donmai.us/post?tags='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://danbooru.donmai.us/post?tags='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span id="cntdwn"/
			@notifier.call "Advertised...\r"
			sleep(10)
			begin
				@agent.get('http://danbooru.donmai.us/post?tags='+@arg.uriEncode+'&page='+@page.to_s)
			rescue
				return false
			end
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/post/show/")
		array.shift
		array.each{|e|
			bookmark=0
=begin
			if e=~/^(\d+).+?([0-9a-f]+\.(jpeg|jpg|png|gif))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2])
			end
=end
			if e=~/^(\d+).+?([0-9a-f]+)\.jpg/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end
	alias member_next tag_next

	def crawl
		@content.each_with_index{|e,i| # e[0] -> id, e[1] -> Internal ID
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				["jpg","png","gif","jpeg","err"].each{|ext|
					if ext=="err" then raise "[Programmer's fault] failed "+e[0] end
					begin
						@agent.get("http://danbooru.donmai.us/data/"+e[1]+"."+ext, [], 'http://danbooru.donmai.us/') #2.1 syntax
						@enter_critical.call
						@agent.page.save_as(e[0]+"."+ext)
						@exit_critical.call
						sleep(@sleep)
					rescue
						sleep(1)
					else
						break
					end
					#search next ext.
				}
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
