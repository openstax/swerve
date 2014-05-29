
class Hash
  def get_deep(*fields)
    fields.inject(self) {|acc,e| acc[e] if acc}
  end
end
