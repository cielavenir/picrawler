#coding:utf-8

#Picrawler under CC0
#Picrawler::Pixiv module

require 'json'

class Picrawler::Pixiv
	def initialize(options={})
		@agent=Mechanize.new
		@agent.robots=false
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","novel","tag","tagillust","tagcomic","tagnovel","response"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.fetch_nested(*["pixiv.net","/","PHPSESSID"])
				unless @agent.cookie_jar.jar["pixiv.net"]["/"]["PHPSESSID"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.pixiv.net/login.php').form_with(:action=>'/login.php')
		form.pixiv_id = user
		form.pass = pass
		form.checkbox_with("skip").check
		if @agent.submit(form).body.resolve =~ /ログアウト/ || @agent.submit(form).body.resolve =~ /Logout/
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
		@__cnt__=1
	end

	def member_first(options={})
		setup(options)
		@novel=false
		ret=member_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/member_illust.php?id='+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/member_illust.php?id='+@arg+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("class=\"image-item \"><a href=\"/member_illust.php?mode=medium&amp;illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2, $3])
			end
=end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def novel_first(options={})
		setup(options)
		@novel=true
		ret=novel_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/novel/member.php?id='+@arg+"\n" end
		return ret
	end

	def novel_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/novel/member.php?id='+@arg+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/novel/show.php?id=")
		array.shift
		array.each{|e|
			unless e=~/ui-scroll-view/ then next end #lol

			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		@novel=false
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/search.php?s_mode=s_tag&word='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/search.php?s_mode=s_tag&word='+@arg.uriEncode+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.gsub(/<!--.*?-->/m,'').split("class=\"image-item \"><a href=\"/member_illust.php?mode=medium&amp;illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2, $3])
			end
=end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def tagillust_first(options={})
		setup(options)
		@novel=false
		ret=tagillust_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/search.php?s_mode=s_tag&manga=0&word='+@arg+"\n" end
		return ret
	end

	def tagillust_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/search.php?s_mode=s_tag&manga=0&word='+@arg.uriEncode+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.gsub(/<!--.*?-->/m,'').split("class=\"image-item \"><a href=\"/member_illust.php?mode=medium&amp;illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2, $3])
			end
=end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def tagcomic_first(options={})
		setup(options)
		@novel=false
		ret=tagcomic_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/search.php?s_mode=s_tag&manga=1&word='+@arg+"\n" end
		return ret
	end

	def tagcomic_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/search.php?s_mode=s_tag&manga=1&word='+@arg.uriEncode+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.gsub(/<!--.*?-->/m,'').split("class=\"image-item \"><a href=\"/member_illust.php?mode=medium&amp;illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2, $3])
			end
=end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def tagnovel_first(options={})
		setup(options)
		@novel=true
		ret=tagnovel_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/novel/search.php?s_mode=s_tag&word='+@arg+"\n" end
		return ret
	end

	def tagnovel_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/novel/search.php?s_mode=s_tag&word='+@arg.uriEncode+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.gsub(/<!--.*?-->/m,'').split("<a href=\"/novel/show.php?id=")
		array.shift
		array.each{|e|
			unless e=~/ui-scroll-view/ then next end #lol

			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def response_first(options={})
		options={}
		@novel=false
		ret=response_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/response.php?type=illust&id='+@arg+"\n" end
		return ret
	end

	def response_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/response.php?type=illust&id='+@arg+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		cont=@agent.page.body.resolve.split('<div class="response">')[2] #fixme
		array=cont.split("<a href=\"member_illust.php?mode=medium&illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2, $3])
			end
=end
			if e=~/^(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		@content.uniq!
		sleep(@sleep)
		return true
	end

	def crawl
		if @novel
			@content.each_with_index{|e,i| # e -> ID
				if @filter.include?(e)
					if @fast then
						@__cnt__-=1
						@seek_end=true if @__cnt__<=0
					end
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
			@content.each_with_index{|id,i| # e[0] -> ID, e[1] -> base URL, e[2] -> ext
				if @filter.include?(id)
					if @fast then
						@__cnt__-=1
						@seek_end=true if @__cnt__<=0
					end
				else
					#puts "http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id
					@agent.get("http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id, [], 'http://www.pixiv.net/') #2.1 syntax
					html=@agent.page.body.resolve.split('<body',2)[1]
					ugoira=html.index('pixiv.context.ugokuIllustFullscreenData  = ')
					if ugoira
						html=~/pixiv.context.ugokuIllustFullscreenData  = (.+?);/
						json=JSON.parse($1)
						@agent.get(json['src'], [], "http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id) #2.1 syntax
						sleep(1)
						zip=zip_open(@agent.page.body)
						if !zip
							@notifier.call "[Warn] Cannot extract ugoira. Please install gem: rubyzip or zipruby.\n"
							next
						end
						Dir.mkdir(id)
						json['frames'].each{|e|
							buffer=zip_decode(zip,e['file'])
							File.open(id+'/'+e['file'],'wb'){|f|f.syswrite(buffer)}
						}
						@notifier.call sprintf("Page %d %d/%d              \r",@page,i+1,@content.length)
						next
					end

					unless
						html=~/(http\:\/\/i[0-9]*\.pixiv\.net\/img[0-9]{2,}\/img\/[0-9a-zA-Z_-]+?\/#{id}_m\.(jpeg|jpg|png|gif)(\?[0-9]+)?)/m ||
						html=~/(http\:\/\/i[0-9]*\.pixiv\.net\/c\/600x600\/img-master\/img\/[0-9\/]+?\/#{id}_p0_master[0-9]+\.(jpeg|jpg|png|gif)(\?[0-9]+)?)/m
					then
						raise "[Developer's fault] Picture URL scheme changed"
					end
					base=$1
					ext=$2 # used only in comic-legacy
					comic=html.index('member_illust.php?mode=manga&amp;illust_id='+id)
					sleep(1)
					if comic
						url_comic=base.sub(/#{id}_m\./,"#{id}_big_p0.") # legacy URL
						#Dir.mkdir(id)
						big=true
						begin #big
							if base.include?('/img-master/')
								@agent.get("http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=#{id}&page=0", [], "http://www.pixiv.net/member_illust.php?mode=manga&illust_id="+id) #2.1 syntax
								sleep(1)
								@agent.page.body=~/img src="(.+?)"/
								url_comic=$1
								ext=url_comic.split('.')[-1]
								ext=ext.split('?')[0] if ext.include?('?')
								raise unless url_comic.include?('big') # goto normal
							end
							@agent.get(url_comic, [], "http://www.pixiv.net/member_illust.php?mode=manga&illust_id="+id) #2.1 syntax
							Dir.mkdir(id)
							@enter_critical.call
							@agent.page.save_as(id+"/"+id+"_big_p0."+ext)
							@exit_critical.call
							sleep(@sleep)
						rescue #normal
							url_comic=url_comic.sub(/#{id}_big_p0\./,"#{id}_p0.")
							big=false
							# *** if exception is thown here, something is really wrong. ***
							@agent.get(url_comic, [], "http://www.pixiv.net/member_illust.php?mode=manga&illust_id="+id) #2.1 syntax
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
								@agent.get(url_comic, [], "http://www.pixiv.net/member_illust.php?mode=manga&illust_id="+id) #2.1 syntax
								break if @agent.page.body.empty?
								@enter_critical.call
								@agent.page.save_as(id+"/"+id+(big ? "_big":"")+"_p"+j.to_s+"."+ext)
								@exit_critical.call
								sleep(@sleep)
								@notifier.call sprintf("Page %d %d/%d Comic %d\r",@page,i+1,@content.length,j)
							end
						rescue; end
					else #illust
						if @agent.page.body=~/img (.*?)src="(.+?)" class="original-image"/
							ext=$2.split('.')[-1]
							ext=ext.split('?')[0] if ext.include?('?')
							@agent.get($2, [], "http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id) #2.1 syntax
						else
							@agent.get("http://www.pixiv.net/member_illust.php?mode=big&illust_id=#{id}&page=0", [], "http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id) #2.1 syntax
							sleep(1)
							@agent.page.body=~/img src="(.+?)"/
							ext=$1.split('.')[-1]
							ext=ext.split('?')[0] if ext.include?('?')
							@agent.get($1, [], "http://www.pixiv.net/member_illust.php?mode=medium&illust_id="+id) #2.1 syntax
						end
						@enter_critical.call
						@agent.page.save_as(id+"."+ext)
						@exit_critical.call
						sleep(@sleep)
					end
				end
				@notifier.call sprintf("Page %d %d/%d              \r",@page,i+1,@content.length)
			}
		end
	end
end
