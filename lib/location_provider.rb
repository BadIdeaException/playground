module LocationProvider
  def location                                          
    unless @location
      path = Location.detect(Dir.pwd)
      raise 'Could not find a playgrounds directory' if path.nil?
      @location = Location.new(path, File.join(path, '.templates'))                                         
    end
    @location                               
  end 
end