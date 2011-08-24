# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'livereload' do
  watch(%r{app/.+\.(erb|haml)})
  watch(%r{app/helpers/.+\.rb})
  # watch(%r{(public/|app/assets).+\.(css|js|html)})
  watch(%r{(app/assets/stylesheets/.+)(?:\.(?:css|s[ac]ss|erb)+)}) { |m|
    m[1] + '.css'
  }
  watch(%r{(app/assets/javascripts/.+)(?:\.(?:js|coffee|erb)+)}) { |m|
    m[1] + '.js'
  }
  # watch(%r{config/locales/.+\.yml})
end
