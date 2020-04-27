# frozen_string_literal: true

# Keep this in-sync with disclosure-backend-static and odca-jekyll.
class Slugify
  def self.slug(str)
    I18n
      .transliterate(str || '')
      .downcase
      .gsub(/[^a-z0-9-]+/, '-')
  end
end
