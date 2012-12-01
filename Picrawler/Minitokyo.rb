#coding:utf-8

#Picrawler under CC0
#Picrawler::Minitokyo module
#I won't update this module out of alpha...

class Picrawler::Minitokyo
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
	end

	def list() return ["tid"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["minitokyo.net","/","minitokyo_hash"])
				unless @agent.cookie_jar.jar["minitokyo.net"]["/"]["minitokyo_hash"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://my.minitokyo.net/login').form_with(:action=>"http://my.minitokyo.net/login")
		form.username = user
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

	def tid_first(options={})
		setup(options)
		ret=tid_next
		if ret then @notifier.call 'Browsing http://browse.minitokyo.net/gallery?tid='+@arg+'&index=3&order=id'+"\n" end
		return ret
	end

	def tid_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://browse.minitokyo.net/gallery?tid='+@arg+'&index=3&order=id&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/Next &raquo;/ then @seek_end=true end
		@content=[]
		body=@agent.page.body.resolve.split("<ul class=\"scans\">")[1]
		array=body.split("</li>")
		#array.shift
		array.each{|e|
			bookmark=0

			if e=~/src=\"http\:\/\/static2\.minitokyo\.net\/thumbs\/([0-9a-z\/]+)\.(jpeg|jpg|png|gif)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1+"."+$2)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> filename
			if @filter.include?(File.basename(e,".*"))
				if @fast then @seek_end=true end
			else
				@agent.get("http://static.minitokyo.net/downloads/"+e, [], 'http://gallery.minitokyo.net/') #2.1 syntax
				@agent.page.save_as(File.basename(e)) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
