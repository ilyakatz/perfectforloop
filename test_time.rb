dir = "/Users/katzmopolitan/buftimer"
ls = Dir.entries(dir)
ls = ls.drop(2) # remove . and ..
ExtensionsRegex = "(rb|haml)"

sessions = Hash.new
ls.each do |filename|
  # there can be multiple files for a given VIM session
  # if VIM was opened for may days in a row
  filename =~ /(.*\.\d+)\.\d{4}\.\d{2}.\d{2}/
  session_name = $1
  full_file_name = "#{dir}/#{filename}"

  # session hash will contain the last filename
  # for a given vim session
  sessions[session_name] = full_file_name

  process_files(sessions.values)
end

def process_files(filenames)

  filenames.each do |filename|
    process_file(filename)
  end;1

end

def process_file(filename)
  tests, code = [0, 0]
  File.foreach(filename).with_index do |line, line_num|
    if line =~ /.*#{ExtensionsRegex}/
        t, c = parse(line)

      unless t
        raise "Tests is nil: #{line}"
      end

      unless c
        raise "Code is nil: #{line}"
      end

      tests += t
      code += c
    end
  end

  if tests > 0 and code > 0
    puts "#{tests} - #{code} - #{ filename }"
  end
end

def parse(line)
  line =~ /\s*\d+\s+(\d+):(\d+):(\d+)\s+(.*.#{ExtensionsRegex})/
  hours = $1
  minutes = $2
  seconds = $3
  total_seconds =  seconds.to_i + 60 * minutes.to_i * 3600 * hours.to_i

  ruby_file = $4
  if ruby_file.nil?
    raise "#{line}"
  end

  tests, code = [0, 0]
  if total_seconds > 0
    #puts "#{test?(ruby_file)} - #{total_seconds} - #{ruby_file}"
    if test?(ruby_file)
      tests += total_seconds
    else
      code += total_seconds
    end

    return [tests, code]
  else
    return [0,0]
  end

end

def test?(filename)
  !!(filename =~ /_spec/)
end
