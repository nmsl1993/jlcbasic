# ruby -w
#
# Fix up symbol names JLC library
#
require 'kicad'
require 'debug'

k = KiCad.load('jlcbasic.kicad_sym').value

renames = []

k.all_symbol.
  each do |s|
    # Only if not yet renamed:
    if s.id != s['PartNumber']
      # puts "Skipping #{s.id} which is a #{s['PartNumber']}"
      next
    end

    # Only RLC:
    # next unless ['R', 'L', 'C'].include?(s['Reference'])

    # Extract the value, unit and @frequency if any - better than the previous script di
    # (previous batch script didn't get fractional numbers correctly)
    description = s['Description']
    match = /.*\b(?<![0-9.])(?<value>[0-9]+(\.[0-9]+)?)(?<unit>[fpnuµmkM]?[ΩFH](@[0-9]+MHz)?)\b/.match(description)
    next unless match
    value = match['value']
    unit = match['unit']

    package_match = /\b[01][0-9][0-9][0-9]\b/.match(description)
    next unless package_match
    package = package_match[0]

    puts "Setting value and name of #{s.id} to #{value}#{unit}, package #{package}"

    # Save the values
    new_name = "#{value}#{unit}-#{package}"
    old = s.id
    renames.append([old, new_name])

    # Rename the symbol and reset the value
    s.id = new_name
    s['Value'] = value+unit

    # Rename the dependent child symbols too:
    s.all_symbol.each do |child|
      chold = child.id
      pattern = %r{\<#{old}_}
      chnew = chold.gsub(pattern, "#{new_name}_")
      child.id = chnew
    end
  end

File.open('rewrite.kicad_sym', 'w') { |f| f.puts k.emit }

# File for use with sed -E:
File.open('renames.sed', 'w') { |f| renames.each{|old, new| f.puts %Q{s/#{old}([_"])/#{new}\\1/} } }
