module StackMaster
  class StackDependency
    def initialize(stack_definition, config)
      @stack_definition = stack_definition
      @config = config
    end

    def outdated_stacks
      outdated_stacks = []
      @config.stacks.collect do |stack|
        ParameterLoader.load(stack.parameter_files).each_value do |value|
          if value['stack_output'] && value['stack_output'] =~ %r(#{@stack_definition.stack_name}/)
            if outdated?(Stack.find(@config.region, stack.stack_name), value['stack_output'].split('/').last)
              outdated_stacks.push stack
              break
            end
          elsif value['stack_outputs']
            value['stack_outputs'].each do |output|
              if output =~ %r(#{@stack_definition.stack_name}/) && outdated?(Stack.find(@config.region, stack.stack_name), output.split('/').last)
                outdated_stacks.push stack
                break
              end
            end
          end
        end
      end
      outdated_stacks
    end

    private

    def outdated?(dependent_stack, output_key)
      stack_output = output_value(output_key)
      dependent_input = dependent_stack.parameters[output_key.camelize]
      dependent_input != stack_output
    end

    def output_value(key)
      updated_stack.outputs.select { |output_type| output_type[:output_key] == key }.first[:output_value]
    end

    def updated_stack
      @stack ||= Stack.find(@stack_definition.region, @stack_definition.stack_name)
    end
  end
end
