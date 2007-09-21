# = SFCcustom
# Ruby interface for SFC's Custom templating engine
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
require 'cgi'
require 'net/http'
require 'xmlsimple' unless defined?(XmlSimple)
require 'digest/md5'
require 'base64'
require 'builder'

class SFCcustomResultException < Exception; end
class SFCcustomTemplateDoesNotExist < SFCcustomResultException; end

class SFCcustom
  attr_reader :api_key, :host, :api
  
  def initialize(api_key = '464809cd2debb66da895ce171c95c70c')
    @api_key  = api_key
    @host     = 'custom.sfcgraphics.com'
    @api      = '/batch.php'
  end

  def fonts
    []
  end

  # Upload a new template to SFCcustom, +data+ can either be a Base64-encoded
  # string or a Tempfile or File object. In either case it must be a PDF file
  # with PDFlib blocks. Returns a hash with :status and :blocks
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
  
  # Delete an existing template, return true or false on success or failure
  def delete(name)
    r = request('DeleteTemplate', { :name => name })
    return r['status'] == ' ok '    
  end
  
  def generate(name, params, resize = nil, cache = true, copy = nil)
    request('GenerateCustom', { :name => name, :data => params, :resize => resize, :cache => cache, :copy => copy})
  end
  
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
  
  def request(type, params = nil)
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
                  else
                    blo.url(v['url'])
                  end
                  blo.fitmethod(v['fitmethod']) if v['fitmethod']
                  blo.rotate(v['rotate']) if v['rotate']
                  blo.position(v['position']) if v['position']
                else
                  if v.is_a?(String)
                    blo.value(v)
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
    
    puts xml
    
    http = Net::HTTP.new(host, 80)
    res = http.post("http://#{host}#{api}", "xml=#{xml}", {'Accept' => 'application/xml'})
    
    puts res.body
    
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
    
    return result
  end
end