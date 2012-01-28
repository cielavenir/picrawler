#coding:utf-8

#Picrawler under CC0
#Picrawler::Tinami module
#!!! Not implemented yet. Too many modes... !!!

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

class Picrawler::Tinami
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

	def list() return [] end

	def open(user,pass,cookie)
		raise "not implemented yet."

		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["www.tinami.com"]
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

	def member_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=member_next
		if ret then puts 'Browsing '+arg end
		return ret
	end

	def member_next
	end

	def tag_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=tag_next
		if ret then puts 'Browsing '+arg end
		return ret
	end

	def tag_next
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
