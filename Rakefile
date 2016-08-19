require "rake"

task :clean do
  sh("bundle exec jekyll clean")
end

task :up => :clean do
  exec("bundle exec jekyll serve")
end
