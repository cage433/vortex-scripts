def prefix_indent(texts, width)
  indent = " " * width
  texts.collext { |t| indent + t }
end

def assert_type(thing, expected_type, allow_null: false)
  if thing.nil? 
    raise "Null not allowed when checking for type #{expected_type}" unless allow_null
  else
    raise "Type mismatch #{thing}, #{thing.class} - expected #{expected_type}" unless thing.is_a?(expected_type)
  end
  thing
end

def assert_collection_type(things, expected_type)
  things.each do |thing|
    raise "Collection type mismatch #{thing}, #{thing.class} - expected #{expected_type}" unless thing.is_a?(expected_type)
  end
  things
end

def is_nil_or_blank?(t)
  t.nil? || (t.class == String && t.strip == "")
end

def is_equal_ignoring_nil_or_blank?(l, r)
  if is_nil_or_blank?(l) && is_nil_or_blank?(r)
    true
  else
    l == r
  end
end

def compare_with_nils(l, r)
    if l == r
      0
    elsif l.nil?
      -1
    elsif r.nil?
      1
    else
      l <=> r
    end
end
