require "rake"

task :clean do
  sh("bundle exec jekyll clean")
end

task :up => :clean do
  exec("bundle exec jekyll serve")
end

task :build => :clean do
  sh("bundle exec jekyll build")
end

task :push => :build do
  sh("s3_website push --verbose")
end
