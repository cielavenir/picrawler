#coding:utf-8

#Picrawler under CC0
#Picrawler gateway module

require "rubygems"
require "mechanize"
require "cgi"
require "fileutils"
require "pathname" if RUBY_VERSION < '1.9'

#require_relative shouldn't be used. Picrawler.rb might be called as symlink.

Version = "0.23.130324"

class Object
	public
	def assureArray
		return self.is_a?(Array) ? self : [self]
	end
	def extract(h,overwrite=false)
		h.each{|k,v|
			if overwrite || !self.instance_variable_defined?('@'+k) then
				self.instance_variable_set('@'+k,v) #k should always be String
			end
		}
	end
end

class String
	def resolve(enc="UTF-8") #must be called if you use regexp for Mechanize::Page#body
		if RUBY_VERSION >= '1.9' then self.force_encoding(enc) end
		return self
	end
	def uriEncode() CGI.escape(self) end 
	def uriDecode() CGI.unescape(self) end
	def dirname()   File.dirname(self) end
	def realpath
		if RUBY_VERSION < '1.9'
			Pathname(self).realpath.to_s
		else
			File.realpath(self)
		end
	end
end

if Mechanize::VERSION >= '2.2'
#It seems save_as method was removed in 2.2... I won't fix directly, for compatibility.
	class Mechanize::File
		alias_method :save_as, :save
	end
	class Mechanize::Image
		alias_method :save_as, :save
	end
	class Mechanize::Page
		alias_method :save_as, :save
	end
end

###Libraries
#Ini Reader/Writer http://d.hatena.ne.jp/white-azalea/20081109/1226244784
class Ini
	def initialize(targetFileName = "./default.ini")
		@targetFile = targetFileName
		if File.exists?(@targetFile) then self.load end
	end

	def load()
		open(@targetFile,"r"){|file|
			@configHash = Hash.new
			currentSection = ""
			@configHash[currentSection] = Hash.new
			while line = file.gets do
				line.chomp!
				if line =~ /^(\[.+\])/ #section
					#sectionString = line.scan(/^\[.+\]/)
					#if sectionString.size==0 then raise("file format is invalid. null section is found.") end
					currentSection = $1 #sectionString[0]
					length = currentSection.size
					name = currentSection[1..length-2]
					currentSection = name
					#p currentSection
					@configHash[currentSection] = Hash.new
				elsif line=~/^[;#]/ then next #comment
				else #data
					if line.size==0 then next end
					parsed = line.split("=")
					if parsed.size!=2 then next end
					#if !currentSection || currentSection=="" then raise("currentSection is unset. line(#{file.lineno})=#{line}") end
					@configHash[currentSection][parsed[0].strip] = parsed[1].strip
				end
			end
		}
	end
  
	def get() return @configHash end
	def [](str) return @configHash[str] end

	def put(saveFileName="default.ini",saveTargetData=@configHash)
		open(saveFileName,"w"){|fp|
=begin
			#group
			if saveTargetData.key?("groups")
				fp.puts("[groups]")
				saveTargetData["groups"].each{|key,value|
					fp.puts(key + "=" + value)
				}
				saveTargetData.delete("groups")
			end
=end
			#write
			saveTargetData.each{|section,inner|
				fp.puts("[" + section + "]")
				inner.each{|key,value|
					fp.puts(key + "=" + value)
				}
			}
		}
	end
end

#String.encode for Ruby1.8 http://www.ownway.info/Blog/2011/06/ruby-182-stringencode-1.html
if RUBY_VERSION < '1.9.0' then
	begin
		#raise "You selected to avoid LGPL in any ways"
		require 'iconv' #if iconv is loadable
		class String
			@encoding = nil
			#def set_encoding(encoding)
			#	@encoding = encoding
			#end

			def encode(to_encoding, from_encoding)
=begin
				if from_encoding == nil
					if @encoding == nil
						f_encoding = Kconv::AUTO
					else
						f_encoding = @encoding
					end
				else
					f_encoding = get_kconv_encoding(from_encoding)
				end
=end
				result = Iconv::conv(to_encoding, from_encoding, self)
				#result.set_encoding(to_encoding)
				return result
			end
			def encode!(to_encoding, from_encoding) self.replace(encode(to_encoding, from_encoding)) end
		end
	rescue
		require 'kconv' #fallback to kconv

		class String
			@encoding = nil
			#def set_encoding(encoding)
			#	@encoding = encoding
			#end

			def encoding
				if @encoding != nil
					return @encoding
				else
					case Kconv.guess(self)
						when Kconv::JIS
							return "ISO-2022-JP"
						when Kconv::SJIS
							return "Shift_JIS"
						when Kconv::EUC
							return "EUC-JP"
						when Kconv::ASCII
							return "UTF-8"
							#return "ASCII"
						when Kconv::UTF8
							return "UTF-8"
						#when Kconv::UTF16
						#	return "UTF-16BE"
						when Kconv::UNKNOWN
							return nil
						when Kconv::BINARY
							return nil
						else
							return nil
					end
				end
			end

			#def encode(to_encoding, from_encoding = nil, options = nil)
			def encode(to_encoding, from_encoding)
				if from_encoding == nil
					if @encoding == nil
						f_encoding = Kconv::AUTO
					else
						f_encoding = @encoding
					end
				else
					f_encoding = get_kconv_encoding(from_encoding)
				end

				result = Kconv::kconv(self, get_kconv_encoding(to_encoding), f_encoding)
				#result.set_encoding(to_encoding)
				return result
			end
			def encode!(to_encoding, from_encoding) self.replace(encode(to_encoding, from_encoding)) end

			def get_kconv_encoding(encoding)
				if encoding != nil
					case encoding.upcase
						when "ISO-2022-JP"
							return Kconv::JIS
						when "SJIS"
							return Kconv::SJIS
						when "SHIFT_JIS"
							return Kconv::SJIS
						when "Shift_JIS"
							return Kconv::SJIS
						when "CP932"
							return Kconv::SJIS
						when "WINDOWS-31J"
							return Kconv::SJIS
						when "EUC-JP"
							return Kconv::EUC
						when "ASCII"
							return Kconv::ASCII
						when "UTF-8"
							return Kconv::UTF8
						#when "UTF-16BE"
						#	return Kconv::UTF16
						else
							raise "Unsupported Encoding: You must prepare iconv or use Ruby 1.9."
							#return Kconv::UNKNOWN
					end
				end
			end
		end
	end
end

class Hash
	def exists_rec?(a)
		#if a.length<1 then return false
		if !self.include?(a[0]) then return nil end           #if not found
		if a.length==1 then return self[a[0]] end             #if found and last
		if !self[a[0]].instance_of?(Hash) then return nil end #if not last and child not hash
		return self[a[0]].exists_rec?(a[1..-1])               #check child
	end
end
###Libraries end

class Picrawler
	attr_reader :pwd # Perform Dir.chdir(pic.pwd) after using.

	def initialize(conf,notifier)
		@pwd=Dir.pwd
		@notifier=notifier

		unless File.exist?(conf)
			raise "cannot find "+conf
		end
		@ini=Ini.new(conf)

		@pic=nil
		@encoding=@ini["General"]["encoding"]
		if @encoding==nil
			@encoding="CP932"
		end
		@cookie=@ini["General"]["cookie"]
		if @cookie==nil
			@cookie=File.expand_path("Picrawler.yaml")
		else
			@cookie=File.expand_path(@cookie)
		end

		@service_list=(Dir.glob(__FILE__.realpath.dirname+"/Picrawler/*.rb").map{|e| File.basename(e,".*")}-["Readme"]).sort
	end
	def encoding() return @encoding end
	def list() return @service_list end

	def open(service)
		Dir.chdir(@pwd)

		unless @service_list.include?(service)
			@notifier.call "[Error] Website module not available (Website module name is case-sensitive).\n"
			return false
		end
		unless @ini[service]
			@notifier.call "[Error] Website not registered (Website module name is case-sensitive).\n"
			return false
		end
		sleeptime=@ini[service]["sleep"]
		if sleeptime!=nil
			sleeptime=sleeptime.to_f
			if sleeptime < 1
				@notifier.call "[Error] sleep must be 1 or more (2 or more is recommended).\n"
				return false
			end
			if sleeptime < 2
				@notifier.call "[Warn] sleep should be 2 or more to avoid ban.\n"
				#return false
			end
		else
			sleeptime=3 #default 3sec
		end

		savedir=@ini[service]["savedir"]
		if savedir!=nil
			savedir.encode!(@encoding,"UTF-8")
			FileUtils.mkpath(savedir)
			Dir.chdir(savedir)
		end

		require File.expand_path(__FILE__.realpath.dirname+"/Picrawler/"+service+".rb")
		@pic=Picrawler.const_get(service).new({:encoding=>@encoding,:sleep=>sleeptime,:notifier=>@notifier})
		ret=@pic.open(@ini[service]["user"],@ini[service]["pass"],@cookie)	
		if ret==-1
			@notifier.call "[Error] Login Failed.\n"
			return false
		elsif ret==0
			@notifier.call "Cookie Expired, re-logged in.\n"
		elsif ret==1
			@notifier.call "Use current credential.\n"
		else
			@notifier.call "[Error] Unknown error!\n"
			return false
		end
		return true
	end

	def mode_list(service)
		unless @service_list.include?(service)
			@notifier.call "Website module not available (Website module name is case-sensitive).\n"
			return []
		end
		require File.expand_path(__FILE__.realpath.dirname+"/Picrawler/"+service+".rb")
		@pic=Picrawler.const_get(service).new({:encoding=>@encoding,:sleep=>-1,:notifier=>@notifier})
		return @pic.list
	end

	#dynamic loading
	def call_first(mode,options={}) return @pic.__send__(mode+"_first",options) end
	def call_next(mode) return @pic.__send__(mode+"_next") end

	def crawl() return @pic.crawl end

	def pcrawl(service,mode,options={})
		unless self.open(service) then return end
		pwd=Dir.pwd
		if options[:dir]==nil then options[:dir]=options[:arg].encode(@encoding,"UTF-8") end
		FileUtils.mkpath(options[:dir])
		Dir.chdir(options[:dir])
		#filter
		options[:filter]=Dir.glob("*").map{|e| File.basename(e,".*")}.sort
		begin
			File.open("filter.txt"){|f|
				options[:filter]+=f.map(&:chomp) #f.readlines
			}
		rescue; end

		unless self.call_first(mode,options)
			@notifier.call "Failed to retrive first page (perhaps not found)\n"
			Dir.chdir(pwd)
			return
		end
		begin
			crawl
		end while self.call_next(mode)
		@notifier.call "\n"
		Dir.chdir(pwd)
	end
end
