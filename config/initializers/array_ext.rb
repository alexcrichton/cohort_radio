class Array
  def halves
    half = size / 2
    [self[0, half], drop(half)]
  end
end
