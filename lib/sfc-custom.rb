# = SFCcustom
# Ruby interface for SFCcustom, a web service for generating dynamic content for print
#
#  == Requirements
#  * xmlsimple (gem install xml-simple)
#  * an SFC API key
#
#  == Usage
#  custom = SFCcustom.new         # => #<SFCcustom:0x605c70 @api_key="464809cd2debb66da895ce171c95c70c", @api="/custom.php", @host="http://custom.sfcgraphics.com">
#  custom.fonts                   # => []
#  custom.templates               # => [#<SFCcustom::Template:0x604a50 @name="Sign">, #<SFCcustom::Template:0x6049b0 @name="Banner">]
#  sign = custom.template('Sign') # => #<SFCcustom::Template:0x604654 @name="Sign">
#  sign.blocks                    # => #<SFCcustom::Template:0x604654 @name="Sign">
#  sign.generate!                 # => #<SFCcustom::Template:0x604654 @name="Sign">

require 'rubygems'
require 'xmlsimple' unless defined?(XmlSimple)
require 'cgi'
require 'net/http'
require 'digest/md5'
require 'base64'
require 'builder'
require 'logger'

class SFCcustomException < Exception; end
class SFCcustomResultException < SFCcustomException; end
class SFCcustomTemplateDoesNotExist < SFCcustomResultException; end

class SFCcustom
  attr_accessor :api_key, :host, :api
  attr_accessor :log_path
  
  def initialize(api_key = '464809cd2debb66da895ce171c95c70c')
    @@logger  = Logger.new(log_path || STDOUT)
    @@logger.level = Logger::DEBUG
    
    @api_key  = api_key
    @host     = 'custom.sfcgraphics.com'
    @api      = '/batch.php'
  end

  def fonts
    []
  end

  # Upload a new template to SFCcustom, by passing a +URL+ of a PDF file with
  # PDFlib blocks. +digest+ (optional) is the MD5 digest of the file, compared
  # after the file has been processed to ensure it has been transferred
  # properly.
  #
  # Returns a hash with :status and :blocks
  def upload(name, url, digest = nil)
    
    r = request('UploadTemplate', { :name => name, :url => url, :digest => digest})
    
    { :status => r['status'] == ' ok ', :blocks => r['blocks'] }
  end

  # Upload a new asset to SFCcustom, +data+ must be a base64-encoded PDF
  # file with PDFlib blocks. Returns a hash with :status and :blocks
  def upload_asset(filename, data)
    r = request('UploadAsset', { :filename => filename, :data => data })
    
    result = { :status => r['status'] == ' ok ', :key => r['key'] }
    
    return result
  end
  
  # Delete an existing template.
  #
  # Return +true+ or +false+ on success or failure, respectively
  def delete(name)
    r = request('DeleteTemplate', { :name => name })
    return r['status'] == ' ok '    
  end
  
  # Generate custom output based on +name+ template and +params+
  def generate(name, params, resize = nil, cache = true, copy = nil, thumbnail = true)
    request('GenerateCustom', { :name => name, :data => params, :resize => resize, :cache => cache, :copy => copy, :thumbnail => thumbnail})
  end
  
  # List the fonts available
  def fonts
    request('ListFonts')
  end
  
  def template(name)
    Template.new(name)
  end
  
  def templates
    templates = request('ListTemplates')
    r = []
    if templates['templates']
      templates['templates'].each do |template|
        r.push(Template.new(template['template']['name'].strip))
      end
      return r
    else
      return nil
    end
  end
  
  class Font
    attr_accessor :name, :family
  end
  
  class Template      
    attr_accessor :name, :customization_signature
    
    def initialize(name)
      @name = name
    end
    
    def blocks
      [Block.new, Block.new]
    end
    
    def generate!
      @customization_signature = Digest::MD5.hexdigest(Time.now.to_s)
    end
    
    def preview_url
      "http://custom.sfcgraphics.com/#{@customization_signature}.jpg" if @customization_signature
    end    
  end
  
  class Block
    attr_accessor :name, :type
  end 
  
  def build_request(type, params = nil)
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!(:xml, :version => "1.0", :encoding => "UTF-8")

    xml = builder.tag!(type) do |b|
      b.authentication do |a|
        a.key(api_key)
      end
      case type
        when 'UploadTemplate':
          b.template do |t|
            t.name(params[:name])
            t.url(params[:url])
            t.digest(params[:digest])
          end

        when 'UploadAsset':
          b.asset do |t|
            t.filename(params[:filename])
            t.data(params[:data])
          end

        when 'DeleteTemplate':
          b.template do |t|
            t.name(params[:name])
          end
        
        when 'ListTemplates':
        
        when 'ListFonts':
        
        when 'GenerateCustom':
          b.template do |t|
            t.name(params[:name])
          end
          if params[:cache]
            b.cache do |t|
              t.cache(params[:cache])
            end
          end
          b.output do |t|
            t.resize(params[:resize]) if params[:resize]
            t.copy(params[:copy]) if params[:copy]
            t.thumbnail(params[:thumbnail].to_s)
          end
          
          b.blocks do |bl|
            params[:data].each do |k, v|
              block_type = case k.to_s 
                when /image|photo|picture/i
                  "image"
                when /pdf/i
                  "pdf"
                else
                  "text"
              end
              
              bl.tag!(block_type) do |blo|
                blo.name(k.to_s)
                if (k.to_s =~ /image|photo|picture|pdf/i) != nil
                  if v.is_a?(String)
                    if (v.to_s =~ /^http/i) != nil
                      blo.url(v)
                    else
                      blo.asset(v)
                    end 
                  elsif block_type == "image" && v.is_a?(Hash)                   
                    v.each do |key, value|
                      blo.tag!(key, value)
                    end
                  elsif v.is_a?(Hash)
                    blo.template do
                      blo.name v['template']
                    end
                    blo.blocks do
                      v.each do |kk, vv|
                        if kk == 'template'
                        else
                          if kk =~ /^PDF/
                            blo.pdf do
                              blo.name kk
                              if vv.match(/http/i)
                                blo.url vv
                              else
                                blo.asset vv
                              end
                            end
                          else
                            blo.text do
                              blo.name kk
                              blo.value {|x| x.cdata!(vv) }
                            end
                          end
                        end
                      end
                    end
                  else
                    blo.url(v['url'])
                  end
                  blo.fitmethod(v['fitmethod']) if v['fitmethod']
                  blo.rotate(v['rotate']) if v['rotate']
                  blo.position(v['position']) if v['position']
                else
                  if v.is_a?(String) || v.nil?
                    blo.value {|x| x.cdata!(v.to_s) }
                  else
                    blo.value(v['value'])
                    blo.font(v['font']) if v['font']
                  end
                end
              end
            end
          end
        else
          # Not much else to do, eh?
      end
    end
    
    @@logger.info "XML Produced: #{xml}"
    
    xml
  end
  
  def send_request(xml)
    if host == 'custom.sfcgraphics.com'
      http = Net::HTTP.new(host, 80)
      res = http.post("http://#{host}#{api}", "xml=#{xml}", {'Accept' => 'application/xml'})    
    else
      request = Net::HTTP::Post.new(api)
      request.body = xml
      res = Net::HTTP.start(host, 80) {|http| http.request(request) }
    end
    
    @@logger.info "Result: #{res.body}"
    
    begin
      result = XmlSimple.xml_in(res.body, { 'ForceArray' => false })

      if result['error']
        case result['error'].to_s.strip
          when "Template does not exist"
            raise SFCcustomTemplateDoesNotExist
          else
            raise SFCcustomResultException          
        end
      end
    rescue
      raise SFCcustomResultException
    end
    
    @@logger.info result.inspect
    
    return result
  end
  
  def request(type, params = nil)
    xml = build_request(type, params)
    send_request(xml)
  end
end