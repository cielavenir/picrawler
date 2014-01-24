#coding:utf-8

#Picrawler under CC0
#Pixiv module V2
#Server vuln PoC: never use for other than research purpose.

class Picrawler::Pixiv2
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","tag","tagillust","tagcomic"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.fetch_nested(*["pixiv.com","/","_pixiv-universe_session"])
				unless @agent.cookie_jar.jar["pixiv.com"]["/"]["_pixiv-universe_session"].expired? then return 1 end #use cookie
			end
		end

=begin
		#normal auth.
		form = @agent.get('http://www.pixiv.net/').form_with(:action=>'/login.php')
		form.pixiv_id = user
		form.pass = pass
		form.checkbox_with("skip").check
		if @agent.submit(form).body.resolve =~ /ログアウト/ || @agent.submit(form).body.resolve =~ /Logout/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
=end
		@notifier.call "Since usual login isn't working, you need to get cookie using pixiv2_login command."
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
		@novel=false
		ret=member_next
		if ret then @notifier.call 'Browsing http://www.pixiv.com/users/'+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.com/users/'+@arg+'?page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/works/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\<i class="bullet-bookmarked"\>\<\/i\>(\d+)/
				bookmark=$1.to_i
			end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		@novel=false
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.pixiv.com/tag/'+@arg+"?full=0\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.com/tag/'+@arg.uriEncodePath+'?p='+@page.to_s+'&full=0')
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/works/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\<i class="bullet-bookmarked"\>\<\/i\>(\d+)/
				bookmark=$1.to_i
			end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tagillust_first(options={})
		setup(options)
		@novel=false
		ret=tagillust_next
		if ret then @notifier.call 'Browsing http://www.pixiv.com/tag/'+@arg+"?full=0&target=illustration\n" end
		return ret
	end

	def tagillust_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.com/tag/'+@arg.uriEncodePath+'?p='+@page.to_s+'&full=0&target=illustration')
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/works/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\<i class="bullet-bookmarked"\>\<\/i\>(\d+)/
				bookmark=$1.to_i
			end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tagcomic_first(options={})
		setup(options)
		@novel=false
		ret=tagcomic_next
		if ret then @notifier.call 'Browsing http://www.pixiv.com/tag/'+@arg+"?full=0&target=manga\n" end
		return ret
	end

	def tagcomic_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.com/tag/'+@arg.uriEncodePath+'?p='+@page.to_s+'&full=0&target=manga')
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/works/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\<i class="bullet-bookmarked"\>\<\/i\>(\d+)/
				bookmark=$1.to_i
			end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
=begin
		if @novel
			@content.each_with_index{|e,i| # e -> ID
				if @filter.include?(e)
					if @fast then @seek_end=true end
				else
					@agent.get("http://www.pixiv.net/novel/show.php?id="+e, [], 'http://www.pixiv.net/') #2.1 syntax
					text=@agent.page.body.split(%Q(id="novel_text">))[1].split("</textarea>")[0]
					@enter_critical.call
					File.open(e+".txt","wb"){|f| f.write(text)}
					@exit_critical.call
					sleep(@sleep)
				end
				@notifier.call sprintf("Page %d %d/%d              \r",@page,i+1,@content.length) 
			}
		else
=end
			@content.each_with_index{|id,i| # e[0] -> ID, e[1] -> base URL, e[2] -> ext
				if @filter.include?(id)
					if @fast then @seek_end=true end
				else
					#puts "http://www.pixiv.com/works/"+id
					@agent.get("http://www.pixiv.com/works/"+id, [], 'http://www.pixiv.com/') #2.1 syntax
					html=@agent.page.body.resolve.split('<body')[1]
					unless html=~/(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/#{id}_m\.(jpeg|jpg|png|gif)(\?[0-9]+)?)/m
						raise "[Developer's fault] Picture URL scheme changed"
					end
					base=$1
					ext=$2
					illust=html.index('/works/'+id+'/large')
					comic=html.index('/works/'+id+'/manga')
					if (illust&&comic) || (!illust&&!comic)
						raise "[Developer's fault] Big link changed"
					end
					sleep(1)
					if illust
						#@agent.get("http://www.pixiv.com/works/"+id+'/large', [], "http://www.pixiv.com/works/"+id)
						#sleep(1)
						@agent.get(base.gsub("_m.","."), [], "http://www.pixiv.com/works/"+id+'/large') #2.1 syntax
						@enter_critical.call
						@agent.page.save_as(id+"."+ext)
						@exit_critical.call
						sleep(@sleep)
					elsif comic
						#Dir.mkdir(id)
						url_comic=base.sub(/#{id}_([0-9a-zA-Z_-]*)m\./,"#{id}_\\1big_p0.")
						big=true
						begin #big
							@agent.get(url_comic, [], "http://www.pixiv.com/works/"+id+'/manga') #2.1 syntax
							Dir.mkdir(id)
							@enter_critical.call
							@agent.page.save_as(id+"/"+id+"_big_p0."+ext)
							@exit_critical.call
							sleep(@sleep)
						rescue #normal
							url_comic=base.sub(/#{id}_([0-9a-zA-Z_-]*)m\./,"#{id}_\\1p0.")
							big=false
							# *** if exception is thown here, something is really wrong. ***
							@agent.get(url_comic, [], "http://www.pixiv.com/works/"+id+'/manga') #2.1 syntax
							Dir.mkdir(id)
							@enter_critical.call
							@agent.page.save_as(id+"/"+id+"_p0."+ext)
							@exit_critical.call
							sleep(@sleep)
						end
						@notifier.call sprintf("Page %d %d/%d Comic 0\r",@page,i+1,@content.length)
						
						begin #start
							j=0
							while true
								j+=1
								url_comic=url_comic.gsub("_p"+(j-1).to_s+"."+ext,"_p"+j.to_s+"."+ext)
								@agent.get(url_comic, [], "http://www.pixiv.com/works/"+id+'/manga') #2.1 syntax
								@enter_critical.call
								@agent.page.save_as(id+"/"+id+(big ? "_big":"")+"_p"+j.to_s+"."+ext)
								@exit_critical.call
								sleep(@sleep)
								@notifier.call sprintf("Page %d %d/%d Comic %d\r",@page,i+1,@content.length,j)
							end
						rescue; end
					end
				end
				@notifier.call sprintf("Page %d %d/%d              \r",@page,i+1,@content.length)
			}
#		end
	end
end
