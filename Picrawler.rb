#coding:utf-8

#Picrawler under CC0
#Picrawler gateway module

require "rubygems"
require "mechanize"
require "uri"
require "fileutils"

class String
	def resolve #must be called if you use regexp for Mechanize::Page#body
		if RUBY_VERSION >= '1.9.0' then self.force_encoding("UTF-8") end
		return self
	end

	def uriEncode
		return URI.encode(self)
	end

	def uriDecode
		return URI.decode(self)
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

			while line = file.gets do
				line.chomp!
				if line =~ /^\[.+\]/ #section
					sectionString = line.scan(/^\[.+\]/)
					if sectionString.size==0 then raise("file format is invalid. null section is found.") end

					currentSection = sectionString[0]
					length = currentSection.size
					name = currentSection[1,length-2]
					currentSection = name
					@configHash[currentSection] = Hash.new
				elsif line=~/^[;#]/ then next #comment
				else #data
					if line.size==0 then next end
					parsed = line.split("=")
					if parsed.size!=2 then next end
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
	def initialize(conf)
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

		@service_list=(Dir.glob(File.dirname(File.realpath(__FILE__))+"/Picrawler/*").map{|e| File.basename(e,".*")}-["Readme"]).sort
	end
	def encoding() return @encoding end
	def list() return @service_list end

	def open(service)
		unless @service_list.include?(service)
			puts "[Error] Website module not available (Website module name is case-sensitive)."
			return false
		end
		unless @ini[service]
			puts "[Error] Website not registered (Website module name is case-sensitive)."
			return false
		end
		sleeptime=@ini[service]["sleep"]
		if sleeptime!=nil
			sleeptime=sleeptime.to_f
			if sleeptime < 1
				puts "[Error] sleep must be 1 or more (2 or more is recommended)."
				return false
			end
			if sleeptime < 2
				puts "[Warn] sleep should be 2 or more to avoid ban."
				return false
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

		require File.expand_path( File.dirname(File.realpath(__FILE__))+"/Picrawler/"+service+".rb" )
		@pic=Picrawler.const_get(service).new(@encoding,sleeptime)
		ret=@pic.open(@ini[service]["user"],@ini[service]["pass"],@cookie)	
		if ret==-1
			puts "[Error] Login Failed."
			return false
		elsif ret==0
			puts "Cookie Expired, re-logged in."
		elsif ret==1
			puts "Use current credential."
		else
			puts "[Error] Unknown error!"
			return false
		end
		return true
	end

	def mode_list(service)
		unless @service_list.include?(service)
			puts "Website module not available (Website module name is case-sensitive)."
			return []
		end
		require File.expand_path( File.dirname(File.realpath(__FILE__))+"/Picrawler/"+service+".rb" )
		@pic=Picrawler.const_get(service).new(@encoding,-1)
		return @pic.list
	end

	#dynamic loading
	def call_first(mode,id,bookmark,fast,filter,start,stop) return @pic.send(mode+"_first",id,bookmark,fast,filter,start,stop) end
	def call_next(mode) return @pic.send(mode+"_next") end

	def crawl() return @pic.crawl end
end
