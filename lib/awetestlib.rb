module Awetestlib

  ::USING_WINDOWS = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) || (RUBY_PLATFORM=~ /mswin|mingw/))

  if !defined?(JRUBY_VERSION).nil?
    ::USING_OSX     = !defined?(JRUBY_VERSION).nil?
  else
    ::USING_OSX     = RUBY_PLATFORM =~ /darwin/
  end

  # @private
  BROWSER_MAP = {
      'FF' => 'Firefox',
      'IE' => 'Internet Explorer',
      'S'  => 'Safari',
      'MS' => 'Mobile Safari',
      'MC' => 'Mobile Chrome',
      'AB' => 'Android Browser',
      'AM' => 'Android Chromium',
      'AC' => 'Android Chrome',
      'GC' => 'Google Chrome',
      'C'  => 'Google Chrome'
  }

  # @private
  BROWSER_ALTERNATES = {
      'OSX'     => { 'IE' => 'S' },
      'Windows' => { 'S' => 'IE' }
  }

  HTML_COLORS = {
      "#{'Black'.downcase}"                => '#000000',
      "#{'Navy'.downcase}"                 => '#000080',
      "#{'DarkBlue'.downcase}"             => '#00008B',
      "#{'MediumBlue'.downcase}"           => '#0000CD',
      "#{'Blue'.downcase}"                 => '#0000FF',
      "#{'DarkGreen'.downcase}"            => '#006400',
      "#{'Green'.downcase}"                => '#008000',
      "#{'Teal'.downcase}"                 => '#008080',
      "#{'DarkCyan'.downcase}"             => '#008B8B',
      "#{'DeepSkyBlue'.downcase}"          => '#00BFFF',
      "#{'DarkTurquoise'.downcase}"        => '#00CED1',
      "#{'MediumSpringGreen'.downcase}"    => '#00FA9A',
      "#{'Lime'.downcase}"                 => '#00FF00',
      "#{'SpringGreen'.downcase}"          => '#00FF7F',
      "#{'Aqua'.downcase}"                 => '#00FFFF',
      "#{'Cyan'.downcase}"                 => '#00FFFF',
      "#{'MidnightBlue'.downcase}"         => '#191970',
      "#{'DodgerBlue'.downcase}"           => '#1E90FF',
      "#{'LightSeaGreen'.downcase}"        => '#20B2AA',
      "#{'ForestGreen'.downcase}"          => '#228B22',
      "#{'SeaGreen'.downcase}"             => '#2E8B57',
      "#{'DarkSlateGray'.downcase}"        => '#2F4F4F',
      "#{'LimeGreen'.downcase}"            => '#32CD32',
      "#{'MediumSeaGreen'.downcase}"       => '#3CB371',
      "#{'Turquoise'.downcase}"            => '#40E0D0',
      "#{'RoyalBlue'.downcase}"            => '#4169E1',
      "#{'SteelBlue'.downcase}"            => '#4682B4',
      "#{'DarkSlateBlue'.downcase}"        => '#483D8B',
      "#{'MediumTurquoise'.downcase}"      => '#48D1CC',
      "#{'Indigo'.downcase}"               => '#4B0082',
      "#{'DarkOliveGreen'.downcase}"       => '#556B2F',
      "#{'CadetBlue'.downcase}"            => '#5F9EA0',
      "#{'CornflowerBlue'.downcase}"       => '#6495ED',
      "#{'MediumAquaMarine'.downcase}"     => '#66CDAA',
      "#{'DimGray'.downcase}"              => '#696969',
      "#{'SlateBlue'.downcase}"            => '#6A5ACD',
      "#{'OliveDrab'.downcase}"            => '#6B8E23',
      "#{'SlateGray'.downcase}"            => '#708090',
      "#{'LightSlateGray'.downcase}"       => '#778899',
      "#{'MediumSlateBlue'.downcase}"      => '#7B68EE',
      "#{'LawnGreen'.downcase}"            => '#7CFC00',
      "#{'Chartreuse'.downcase}"           => '#7FFF00',
      "#{'Aquamarine'.downcase}"           => '#7FFFD4',
      "#{'Maroon'.downcase}"               => '#800000',
      "#{'Purple'.downcase}"               => '#800080',
      "#{'Olive'.downcase}"                => '#808000',
      "#{'Gray'.downcase}"                 => '#808080',
      "#{'SkyBlue'.downcase}"              => '#87CEEB',
      "#{'LightSkyBlue'.downcase}"         => '#87CEFA',
      "#{'BlueViolet'.downcase}"           => '#8A2BE2',
      "#{'DarkRed'.downcase}"              => '#8B0000',
      "#{'DarkMagenta'.downcase}"          => '#8B008B',
      "#{'SaddleBrown'.downcase}"          => '#8B4513',
      "#{'DarkSeaGreen'.downcase}"         => '#8FBC8F',
      "#{'LightGreen'.downcase}"           => '#90EE90',
      "#{'MediumPurple'.downcase}"         => '#9370DB',
      "#{'DarkViolet'.downcase}"           => '#9400D3',
      "#{'PaleGreen'.downcase}"            => '#98FB98',
      "#{'DarkOrchid'.downcase}"           => '#9932CC',
      "#{'YellowGreen'.downcase}"          => '#9ACD32',
      "#{'Sienna'.downcase}"               => '#A0522D',
      "#{'Brown'.downcase}"                => '#A52A2A',
      "#{'DarkGray'.downcase}"             => '#A9A9A9',
      "#{'LightBlue'.downcase}"            => '#ADD8E6',
      "#{'GreenYellow'.downcase}"          => '#ADFF2F',
      "#{'PaleTurquoise'.downcase}"        => '#AFEEEE',
      "#{'LightSteelBlue'.downcase}"       => '#B0C4DE',
      "#{'PowderBlue'.downcase}"           => '#B0E0E6',
      "#{'FireBrick'.downcase}"            => '#B22222',
      "#{'DarkGoldenRod'.downcase}"        => '#B8860B',
      "#{'MediumOrchid'.downcase}"         => '#BA55D3',
      "#{'RosyBrown'.downcase}"            => '#BC8F8F',
      "#{'DarkKhaki'.downcase}"            => '#BDB76B',
      "#{'Silver'.downcase}"               => '#C0C0C0',
      "#{'MediumVioletRed'.downcase}"      => '#C71585',
      "#{'IndianRed'.downcase}"            => '#CD5C5C',
      "#{'Peru'.downcase}"                 => '#CD853F',
      "#{'Chocolate'.downcase}"            => '#D2691E',
      "#{'Tan'.downcase}"                  => '#D2B48C',
      "#{'LightGray'.downcase}"            => '#D3D3D3',
      "#{'Thistle'.downcase}"              => '#D8BFD8',
      "#{'Orchid'.downcase}"               => '#DA70D6',
      "#{'GoldenRod'.downcase}"            => '#DAA520',
      "#{'PaleVioletRed'.downcase}"        => '#DB7093',
      "#{'Crimson'.downcase}"              => '#DC143C',
      "#{'Gainsboro'.downcase}"            => '#DCDCDC',
      "#{'Plum'.downcase}"                 => '#DDA0DD',
      "#{'BurlyWood'.downcase}"            => '#DEB887',
      "#{'LightCyan'.downcase}"            => '#E0FFFF',
      "#{'Lavender'.downcase}"             => '#E6E6FA',
      "#{'DarkSalmon'.downcase}"           => '#E9967A',
      "#{'Violet'.downcase}"               => '#EE82EE',
      "#{'PaleGoldenRod'.downcase}"        => '#EEE8AA',
      "#{'LightCoral'.downcase}"           => '#F08080',
      "#{'Khaki'.downcase}"                => '#F0E68C',
      "#{'AliceBlue'.downcase}"            => '#F0F8FF',
      "#{'HoneyDew'.downcase}"             => '#F0FFF0',
      "#{'Azure'.downcase}"                => '#F0FFFF',
      "#{'SandyBrown'.downcase}"           => '#F4A460',
      "#{'Wheat'.downcase}"                => '#F5DEB3',
      "#{'Beige'.downcase}"                => '#F5F5DC',
      "#{'WhiteSmoke'.downcase}"           => '#F5F5F5',
      "#{'MintCream'.downcase}"            => '#F5FFFA',
      "#{'GhostWhite'.downcase}"           => '#F8F8FF',
      "#{'Salmon'.downcase}"               => '#FA8072',
      "#{'AntiqueWhite'.downcase}"         => '#FAEBD7',
      "#{'Linen'.downcase}"                => '#FAF0E6',
      "#{'LightGoldenRodYellow'.downcase}" => '#FAFAD2',
      "#{'OldLace'.downcase}"              => '#FDF5E6',
      "#{'Red'.downcase}"                  => '#FF0000',
      "#{'Fuchsia'.downcase}"              => '#FF00FF',
      "#{'Magenta'.downcase}"              => '#FF00FF',
      "#{'DeepPink'.downcase}"             => '#FF1493',
      "#{'OrangeRed'.downcase}"            => '#FF4500',
      "#{'Tomato'.downcase}"               => '#FF6347',
      "#{'HotPink'.downcase}"              => '#FF69B4',
      "#{'Coral'.downcase}"                => '#FF7F50',
      "#{'DarkOrange'.downcase}"           => '#FF8C00',
      "#{'LightSalmon'.downcase}"          => '#FFA07A',
      "#{'Orange'.downcase}"               => '#FFA500',
      "#{'LightPink'.downcase}"            => '#FFB6C1',
      "#{'Pink'.downcase}"                 => '#FFC0CB',
      "#{'Gold'.downcase}"                 => '#FFD700',
      "#{'PeachPuff'.downcase}"            => '#FFDAB9',
      "#{'NavajoWhite'.downcase}"          => '#FFDEAD',
      "#{'Moccasin'.downcase}"             => '#FFE4B5',
      "#{'Bisque'.downcase}"               => '#FFE4C4',
      "#{'MistyRose'.downcase}"            => '#FFE4E1',
      "#{'BlanchedAlmond'.downcase}"       => '#FFEBCD',
      "#{'PapayaWhip'.downcase}"           => '#FFEFD5',
      "#{'LavenderBlush'.downcase}"        => '#FFF0F5',
      "#{'SeaShell'.downcase}"             => '#FFF5EE',
      "#{'Cornsilk'.downcase}"             => '#FFF8DC',
      "#{'LemonChiffon'.downcase}"         => '#FFFACD',
      "#{'FloralWhite'.downcase}"          => '#FFFAF0',
      "#{'Snow'.downcase}"                 => '#FFFAFA',
      "#{'Yellow'.downcase}"               => '#FFFF00',
      "#{'LightYellow'.downcase}"          => '#FFFFE0',
      "#{'Ivory'.downcase}"                => '#FFFFF0',
      "#{'White'.downcase}"                => '#FFFFFF',
  }

  VERIFY_MSG     = true
  NO_DOLLAR_BANG = false

  require 'date'
  require 'active_support/all'
  require 'awetestlib/runner'
  require 'yaml'
  require 'andand'
  require 'awetestlib/regression/runner'
  require 'html_validation'
  require 'html_validation/page_validations'
  require 'html_validation/html_validation_result'
  require 'w3c_validators'
  require 'roo'
  require 'pry'

end
