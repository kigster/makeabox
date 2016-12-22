eval File.read("lib/capistrano/tasks/os/#{fetch(:target_os).downcase}.cap")
