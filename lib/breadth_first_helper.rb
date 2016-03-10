require 'ostruct'
class BreadthFirstHelper

  def self.find_shortest_path(start, finish, join_filters)
    traversed = {}                                    # havent seen anything yet
    new_paths = [[self.fake_association(start)]]  # path is empty, tip is the start
    old_paths = []
    while (new_paths.any?)                            # fail when we run out of paths to try
      old_paths = new_paths
      new_paths = []
      old_paths.each do |path|
        tip = path.last
        if tip.klass == finish                        # we found it
          return self.hash_path(path)  # send back the whole path as a hash
        end
        traversed[tip] = 1
        assoc_array = self.associations(tip, join_filters: join_filters).         # list all associations by name
          reject { |a| traversed[a] }.                # remove any we have already looked into
          map { |a| path+[a] }               # path is the first element, tip is the last

        new_paths.push(*assoc_array)                  # add each path-tuple to the list to be searched
      end
    end
    return nil
  end

  def self.fake_association(klass)
    OpenStruct.new(klass: klass)
  end

  def self.associations(klass, options = {})
    join_filters = options[:join_filters] || []

    klass.klass.reflect_on_all_associations.select do |assoc|
      assoc.options[:through].nil? &&
        !should_ignore_association(klass, assoc) &&
          !join_filters.map(&:name).include?(assoc.class_name)
    end
  end

  def self.should_ignore_association(klass, assoc)
    if klass.klass.respond_to?(:associations_to_ignore_for_join)
      klass.klass.associations_to_ignore_for_join.include?(assoc.name)
    else
      false
    end
  end

  def self.hash_path(fullpath)
    fullpath.shift
    fullpath.reverse.inject({}) do |tip, k|
    if (k.klass.respond_to?(:join_condition) && cond = k.klass.join_condition)
      tip[:__and_on] = cond
    end
      { k.name => tip }
    end
  end
end
