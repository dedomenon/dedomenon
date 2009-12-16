class String
  def underscorize
    self.downcase.gsub(/ /, "_")
  end
end
