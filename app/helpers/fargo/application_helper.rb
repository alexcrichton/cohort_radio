module Fargo::ApplicationHelper
  def all_javascripts_included
    javascripts = included_javascripts || []
    Paste::Rails.glue.paste(*javascripts)[:javascripts].map do |s|
      javascript_path s
    end
  end

  def all_stylesheets_included
    javascripts = included_javascripts || []
    css = Paste::Rails.glue.paste(*javascripts)[:stylesheets]
    css += included_stylesheets || []
    css.map do |s|
      stylesheet_path s
    end
  end
end
