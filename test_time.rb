require 'csv'
dir = "/Users/katzmopolitan/Desktop/buftimer"
OUTPUT_CSV="/Users/katzmopolitan/Desktop/buftimer_output.csv"
ExtensionsRegex = "(rb|haml)"

def list_files(dir)
  ls = Dir.entries(dir).sort_by do |x|
    full_file_name = "#{dir}/#{x}"
    File.mtime(full_file_name)
  end
  ls = cleanup_files(ls)
end

def process_directory(dir)

  ls = list_files(dir)

  sessions = Hash.new
  ls.each do |filename|
    # there can be multiple files for a given VIM session
    # if VIM was opened for may days in a row
    filename =~ /(.*\.\d+)\.(\d{4}\.\d{2}.\d{2})/
    session_name = $1
    date = $2
    full_file_name = "#{dir}/#{filename}"

    tests,code,filename = process_file(full_file_name)
    if tests && code
      sessions[session_name] = {test: tests, code: code, date: date }
    end

    if session_name == "buftimer_report.25409"
      binding.pry
    end
  end
  sessions
end

def cleanup_files(ls)
  ls.delete(".")
  ls.delete("..")
  ls.delete(".DS_Store")
  ls
end

def output(sessions)
  CSV.open( OUTPUT_CSV, 'w' ) do |writer|
    writer << ["file","date", "test", "code"]
    sessions.each do |k,v|
      writer << [k, "'#{ v[:date] }'" , v[:test] , v[:code]]
    end

    writer << [
      "Total",
      "",
      sessions.values.collect{|v|v[:test]}.compact.inject{|sum,v| sum + v},
      sessions.values.collect{|v|v[:code]}.compact.inject{|sum,v| sum + v}
    ]
  end
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
    return tests,code,filename
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

sessions = process_directory(dir)
output(sessions)

