module Fargo
  
  def self.config
    return @@config if defined?(@@config)
    
    @@config = YAML.load(ERB.new(File.read("#{Rails.root}/config/fargo.yml")).result)
    
    @@config.symbolize_keys!
    @@config.each_value do |v|
      v.symbolize_keys! if v.respond_to? :symbolize_keys!
    end
    
    @@config
  end
  
end
