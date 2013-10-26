#coding:utf-8

#Picrawler under CC0
#Picrawler::Gelbooru module

class Picrawler::Gelbooru
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
			if @agent.cookie_jar.jar.exists_rec?(["gelbooru.com","/","__cfduid"])
				unless @agent.cookie_jar.jar["gelbooru.com"]["/"]["__cfduid"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://gelbooru.com/index.php?page=account&s=login&code=00').forms.first
		form.field_with("user").value = user
		form.field_with("pass").value = pass
		#form.checkbox_with("remember_me").check
		#if @agent.submit(form).body.resolve =~ /Logout/
		unless @agent.submit(form).body.resolve =~ /Log in/ #lol?
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
		if ret then @notifier.call 'Browsing http://gelbooru.com/index.php?page=post&s=list&tags=user:'+@arg+"\n" end
		return ret
	end

	def tag_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://gelbooru.com/index.php?page=post&s=list&tags='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://gelbooru.com/index.php?page=post&s=list&tags='+@arg.uriEncode+'&pid='+(@page*28).to_s)
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span id="cntdwn"/
			@notifier.call "Advertised...\r"
			sleep(10)
			begin
				@agent.get('http://gelbooru.com/index.php?page=post&s=list&tags='+@arg.uriEncode+'&pid='+(@page*28).to_s)
			rescue
				return false
			end
		end

		unless @agent.page.body.resolve=~/ alt="next"\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a id=\"p")
		array.shift
		array.each{|e|
			bookmark=0
			#if e=~/(\d+).+?(http\:\/\/img.+?\.gelbooru\.com\/thumbs\/[0-9]+\/thumbnail_[0-9a-fA-F\/]+\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/m
			if e=~/(\d+).+?(http\:\/\/simg\.gelbooru\.com\/thumbs\/[0-9]+\/thumbnail_[0-9a-fA-F\/]+\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.sub("/thumbnail_","/").sub("/thumbs/","/images/")])
			end
		}
		@page+=1
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end
	alias member_next tag_next

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				#["jpg","jpeg","png","gif","err"].each{|ext|
				#	if ext=="err" then raise "[Programmer's fault: failed "+e[0] end
				#	begin
						@agent.get(e[1], [], 'http://gelbooru.com/') #2.1 syntax
						@enter_critical.call
						@agent.page.save_as(e[0])
						@exit_critical.call
						sleep(@sleep)
				#	rescue
				#		sleep(1)
				#	else
				#		break
				#	end
				#	#search next ext.
				#}
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end
