module RuboCop::Cop::Lint
  class PathInHelpers < RuboCop::Cop::Base
    extend RuboCop::Cop::AutoCorrector

    def_node_matcher :method_call, '(send nil? $_ ...)'

    MSG = "Don't use _path URL helpers in helper methods; use _url instead.".freeze
    PATH_HELPER = /^[\da-zA-z_]+_path$/.freeze

    def on_send(node)
      method_call(node) do |name|
        next unless name.to_s.match?(PATH_HELPER)

        add_offense(node) do |corrector|
          corrected_call = name.to_s.gsub(/_path$/, '_url')
          corrector.replace(node, node.source.sub(name.to_s, corrected_call))
        end
      end
    end
  end
end
