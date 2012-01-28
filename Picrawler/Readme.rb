#coding:utf-8

#Picrawler under CC0
#Picrawler::Readme module
#!!! Not actual module. Just skeleton. Please never try to load this module. !!!

=begin
Picrawler under CC0
An extendable picture website downloader

You may do anything for this source code.

[Dependency]
Ruby is distributed under 2-clause BSDL or Artistic1.0/GPL (lol).
nokogiri (C) Aaron Patterson / Mike Dalessio / Charles Nutter / Sergio Arbeo / Patrick Mahoney / Yoko Harada under MIT License.
mechanize (C) Michael Neumann / Aaron Patterson / Mike Dalessio / Eric Hodel / Akinori MUSHA under MIT License.

[Note] website modules encoded in other than UTF-8 must encode strings properly or you will get wrong result.
[Note] Cookie YAML cannot be merged between 1.8.x and 1.9.x.

### You need Ruby 1.8.7 / 1.9.1 and Mechanize 2.1 or later. ###
### Sorry, but I use Mechanize#get 2.1 syntax.              ###
As for specifying encoding in Ruby1.8, there should be several cases. Please be aware :p
#Ruby 1.9.x (Debian/Ubuntu)
#!/usr/bin/env ruby1.9.1
#Ruby 1.8 [cannot support website modules encoded other than UTF-8]
#!/usr/bin/ruby -Ku

How to install:
[Windows]
gem install mechanize
[OSX]
After installing Xcode, ( if 10.6(SnowLeopard) or lower, use http://developer.apple.com/devcenter/download.action?path=/Developer_Tools/xcode_3.2.6_and_ios_sdk_4.3__final/xcode_3.2.6_and_ios_sdk_4.3.dmg )
sudo gem install mechanize
[Debian/Ubuntu]
sudo apt-get install libxml2-dev libxslt1-dev
sudo apt-get install ruby1.9.1
sudo gem1.9.1 install mechanize #apt will install 1.0; not suitable

[History]
0.00A1.120125
Parser core.
0.00A2.120126
Added PiXA support.
0.00A3.120127
Separated Site modules.
Added NicoSeiga support.
0.00B1.120127
Added Pixiv support.
0.01.120128
Added Danbooru/DeviantART support.
0.02.120129
Fixed PiXA paging.
Temporary supports Fg.
Added very experimental Tinami support. only illust search is available.

[Creative Commons CC0]
Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer exclusive Copyright and Related Rights (defined below) upon the creator and subsequent owner(s) (each and all, an "owner") of an original work of authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for the purpose of contributing to a commons of creative, cultural and scientific works ("Commons") that the public can reliably and without fear of later claims of infringement build upon, modify, incorporate in other works, reuse and redistribute as freely as possible in any form whatsoever and for any purposes, including without limitation commercial purposes. These owners may contribute to the Commons to promote the ideal of a free culture and the further production of creative, cultural and scientific works, or to gain reputation or greater distribution for their Work in part through the use and efforts of others.

For these and/or other purposes and motivations, and without any expectation of additional consideration or compensation, the person associating CC0 with a Work (the "Affirmer"), to the extent that he or she is an owner of Copyright and Related Rights in the Work, voluntarily elects to apply CC0 to the Work and publicly distribute the Work under its terms, with knowledge of his or her Copyright and Related Rights in the Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be protected by copyright and related or neighboring rights ("Copyright and Related Rights"). Copyright and Related Rights include, but are not limited to, the following:
i.   the right to reproduce, adapt, distribute, perform, display, communicate, and translate a Work;
ii.  moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or likeness depicted in a Work;
iv.  rights protecting against unfair competition in regards to a Work, subject to the limitations in paragraph 4(a), below;
v.   rights protecting the extraction, dissemination, use and reuse of data in a Work;
vi.  database rights (such as those arising under Directive 96/9/EC of the European Parliament and of the Council of 11 March 1996 on the legal protection of databases, and under any national implementation thereof, including any amended or successor version of such directive); and
vii. other similar, equivalent or corresponding rights throughout the world based on applicable law or treaty, and any national implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention of, applicable law, Affirmer hereby overtly, fully, permanently, irrevocably and unconditionally waives, abandons, and surrenders all of Affirmer's Copyright and Related Rights and associated claims and causes of action, whether now known or unknown (including existing as well as future claims and causes of action), in the Work (i) in all territories worldwide, (ii) for the maximum duration provided by applicable law or treaty (including future time extensions), (iii) in any current or future medium and for any number of copies, and (iv) for any purpose whatsoever, including without limitation commercial, advertising or promotional purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each member of the public at large and to the detriment of Affirmer's heirs and successors, fully intending that such Waiver shall not be subject to revocation, rescission, cancellation, termination, or any other legal or equitable action to disrupt the quiet enjoyment of the Work by the public as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason be judged legally invalid or ineffective under applicable law, then the Waiver shall be preserved to the maximum extent permitted taking into account Affirmer's express Statement of Purpose. In addition, to the extent the Waiver is so judged Affirmer hereby grants to each affected person a royalty-free, non transferable, non sublicensable, non exclusive, irrevocable and unconditional license to exercise Affirmer's Copyright and Related Rights in the Work (i) in all territories worldwide, (ii) for the maximum duration provided by applicable law or treaty (including future time extensions), (iii) in any current or future medium and for any number of copies, and (iv) for any purpose whatsoever, including without limitation commercial, advertising or promotional purposes (the "License"). The License shall be deemed effective as of the date CC0 was applied by Affirmer to the Work. Should any part of the License for any reason be judged legally invalid or ineffective under applicable law, such partial invalidity or ineffectiveness shall not invalidate the remainder of the License, and in such case Affirmer hereby affirms that he or she will not (i) exercise any of his or her remaining Copyright and Related Rights in the Work or (ii) assert any associated claims and causes of action with respect to the Work, in either case contrary to Affirmer's express Statement of Purpose.

4. Limitations and Disclaimers.
a. No trademark or patent rights held by Affirmer are waived, abandoned, surrendered, licensed or otherwise affected by this document.
b. Affirmer offers the Work as-is and makes no representations or warranties of any kind concerning the Work, express, implied, statutory or otherwise, including without limitation warranties of title, merchantability, fitness for a particular purpose, non infringement, or the absence of latent or other defects, accuracy, or the present or absence of errors, whether or not discoverable, all to the greatest extent permissible under applicable law.
c. Affirmer disclaims responsibility for clearing rights of other persons that may apply to the Work or any use thereof, including without limitation any person's Copyright and Related Rights in the Work. Further, Affirmer disclaims responsibility for obtaining any necessary consents, permissions or other rights required for any use of the Work.
d. Affirmer understands and acknowledges that Creative Commons is not a party to this document and has no duty or obligation with respect to this CC0 or use of the Work.
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

class Picrawler::Readme
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
		raise "not actual module"

		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["xxx"]
				unless @agent.cookie_jar.jar["xxx"]["/"]["xxx"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('').forms[0]
		form.mail = user
		form.password = pass
		#form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def member_first(arg,bookmark,fast,filter) #Initialize variables then call next
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

	def member_next #HTML Parser
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

	def crawl #actual downloader
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
