def prefix_indent(texts, width)
  indent = " " * width
  texts.collext { |t| indent + t }
end

def assert_type(thing, expected_type)
  raise "Type mismatch #{thing}, #{thing.class} - expected #{expected_type}" unless thing.class == expected_type
end

def assert_collection_type(things, expected_type)
  things.each do |thing|
    raise "Collection type mismatch #{thing}, #{thing.class} - expected #{expected_type}" unless thing.class == expected_type
  end
end
