require "rake"

task :clean do
  sh("bundle exec jekyll clean")
  rm_rf(".asset-cache")
  rm_rf(".sass-cache")
end

task :up do
  exec("bundle exec jekyll serve")
end

task :build do
  sh("bundle exec jekyll build")
end

task :push => :build do
  sh("bundle exec s3_website push --verbose")
end
