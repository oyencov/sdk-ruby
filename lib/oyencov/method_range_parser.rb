require "parser/current"

# This module helps scanning source code files and get the definition line
#   ranges, so we can count how many times a method has been executed.
module OyenCov
  class MethodRangeParser < Hash
    @@parsed_files = {}

    def self.parsed_files
      @@parsed_files
    end

    # Check cache
    def self.[](filepath)
      @filepath = filepath
      @@parsed_files[@filepath] ||= parse_file(@filepath)
    end

    private

    # Considerations:
    # - Some .rb files do not have valid syntax, we can rescue them. However parser
    #   stills stderr
    #
    # @return [Hash<String, >] Hash of methods to their children starting line count. The line count can be used to read how often the method is executed from `Coverage.peek_result`
    private_class_method def self.parse_file(filepath)
      traverse_ast(Parser::CurrentRuby.parse(File.read(filepath)))
        .reverse
        .to_h
        .select do |k, v|
          /\.|\#/.match?(k)
        end.transform_keys do |k|
          k.gsub(/^::/, "")
        end
    rescue Parser::SyntaxError
      {}
    end

    private_class_method def self.declaration_name(node)
      case node.type
      when :begin then ""
      when :defs then ".#{node.children[1]}"
      when :def then "##{node.children[0]}"
      when :class, :module # traverse
        current_name_constant_node = node.children[0]
        full_constant_name = ""
        until current_name_constant_node.children[0].nil?
          full_constant_name = "::#{current_name_constant_node.children[1]}#{full_constant_name}"
          current_name_constant_node = current_name_constant_node.children[0]
        end
        "::#{current_name_constant_node.children[1]}#{full_constant_name}"
      else "Unsupported AST node type: #{node.type}"
      end
    end

    # @return [Integer]
    private_class_method def self.definition_line_num(node)
      definition_lines = node.children.find do |i|
        Parser::AST::Node === i && i.type == :begin
      end || node.children[-1]

      if definition_lines.nil?
        nil
      else
        definition_lines.loc.first_line
      end
    end

    # this be recursion
    # return array of ["node_type/namespace::nam#node_name" => [startline, endline]
    private_class_method def self.traverse_ast(node)
      unless Parser::AST::Node === node
        return nil
      end

      unless %i[begin module class defs def].include?(node.type)
        return nil
      end

      node_children = node.children.find do |i|
        Parser::AST::Node === i && i.type == :begin
      end&.children || [node.children[-1]]

      ownself_name = declaration_name(node)
      ownself_range = definition_line_num(node)

      children_name_range = []

      node_children&.each do |cnode|
        if Array === traverse_ast(cnode)
          children_name_range += traverse_ast(cnode)
        end
      end

      children_name_range.map! do |cnode|
        ["#{ownself_name}#{cnode[0]}", cnode[1]]
      end

      [[ownself_name, ownself_range]] + children_name_range
    end
  end
end
