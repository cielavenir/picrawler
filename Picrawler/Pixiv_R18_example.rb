#coding:utf-8

#Picrawler under CC0
#Picrawler::Pixiv module

#Extending example for Pixiv R18

require File.expand_path(__FILE__.dirname+"/Pixiv.rb")

class Picrawler::Pixiv_R18_example < Picrawler::Pixiv
	def list() return super+["tag_R18"] end

	def tag_R18_first(options={})
		setup(options)
		@novel=false
		ret=tag_R18_next
		if ret then @notifier.call 'Browsing http://www.pixiv.net/search.php?s_mode=s_tag&r18=1&word='+@arg+"\n" end
		return ret
	end

	def tag_R18_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.pixiv.net/search.php?s_mode=s_tag&r18=1&word='+@arg.uriEncode+'&p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/member_illust.php?mode=medium&amp;illust_id=")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)件のブックマーク/
				bookmark=$1.to_i
			end
=begin
			if e=~/^(\d+).+?(http\:\/\/img.+?\.pixiv\.net\/img[0-9]{2,}\/img\/.+?\/\d+_s\.(jpeg|jpg|png|gif))/m #(?:\?[0-9]+)?)/m #just splitting, so I don't have to consider ?[0-9]+ stuff.
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
		sleep(@sleep)
		return true
	end
end
