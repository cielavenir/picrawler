#coding:utf-8

#Picrawler under CC0
#Picrawler::Fg module
#bookmark isn't implemented.

#!!! Not implemented yet. !!!

# syntax: "http://image1.fg-site.net/image/mid/NUM/midID_0_TOTALID.jpg".gsub("/mid","/org")

require "rubygems"
require "mechanize"
require "uri"

class String
	def resolve #must be called if you use regexp for Mechanize::Page#body
		if RUBY_VERSION >= '1.9.0' then self.force_encoding("UTF-8") end
		return self
	end

	def uriEncode
		return URI.encode(self)
	end
end

class Picrawler::Fg
	def initialize(encoding,sleep)
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=encoding
		@sleep=sleep

		@content=[]
		@seek_end=true
		@arg=""
		@bookmark=0
		@fast=false
		@filter=[]
	end

	def list() return ["member","search"] end

	def open(user,pass,cookie)
		raise "Almost completed, but I'm waiting for fg-site renewal."

		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["fg-site.net"]
				unless @agent.cookie_jar.jar["fg-site.net"]["/"]["my_id"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.fg-site.net/users/login/').form_with(:action=>"/users/login")
		form.field_with("data[email]").value = user
		form.field_with("data[password]").value = pass
		form.checkbox_with("data[autologin]").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def member_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=member_next
		if ret then puts 'Browsing http://www.fg-site.net/contents/view/user_id:'+arg+'/' end
		return ret
	end

	def member_next
		#separator: "次の20件"
	end

	def search_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=tag_next
		if ret then puts 'Browsing http://www.fg-site.net/contents/search/sort:created/direction:desc/word:'+arg+'/' end #page:x
		return ret
	end

	def search_next
	end

	def crawl
		@content.each_with_index{|e,i|
			if @filter.include?(File.basename(e,".*"))
				if @fast then @seek_end=true end
			else
				###
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end
