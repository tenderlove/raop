module Net
  class RAOP
  end
end

require 'raop/client'
require 'raop/rtsp'
if RUBY_VERSION >= '1.9.0'
  require 'raop/1_9/client'
else
  require 'raop/1_8/client'
end
