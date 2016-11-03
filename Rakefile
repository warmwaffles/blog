require "rake"

task :clean do
  sh("bundle exec jekyll clean")
end

task :up do
  exec("bundle exec jekyll serve")
end

task :build do
  sh("bundle exec jekyll build")
end

task :push => :build do
  sh("s3_website push --verbose")
end
