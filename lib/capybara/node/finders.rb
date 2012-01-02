module Capybara
  module Node
    module Finders

      ##
      #
      # Find an {Capybara::Element} based on the given arguments. +find+ will raise an error if the element
      # is not found. The error message can be customized through the +:message+ option.
      #
      # If the driver is capable of executing JavaScript, +find+ will wait for a set amount of time
      # and continuously retry finding the element until either the element is found or the time
      # expires. The length of time +find+ will wait is controlled through {Capybara.default_wait_time}
      # and defaults to 2 seconds.
      #
      # +find+ takes the same options as +all+.
      #
      #     page.find('#foo').find('.bar')
      #     page.find(:xpath, '//div[contains(., "bar")]')
      #     page.find('li', :text => 'Quox').click_link('Delete')
      #
      # @param (see Capybara::Node::Finders#all)
      # @option options [String] :message     An error message in case the element can't be found
      # @return [Capybara::Element]           The found element
      # @raise  [Capybara::ElementNotFound]   If the element can't be found before time expires
      #
      def find(*args)
        wait_until { first(*args) or raise_find_error(*args) }
      end

      ##
      #
      # Find a form field on the page. The field can be found by its name, id or label text.
      #
      # @param [String] locator       Which field to find
      # @return [Capybara::Element]   The found element
      #
      def find_field(locator)
        find(:field, locator)
      end
      alias_method :field_labeled, :find_field

      ##
      #
      # Find a link on the page. The link can be found by its id or text.
      #
      # @param [String] locator       Which link to find
      # @return [Capybara::Element]   The found element
      #
      def find_link(locator)
        find(:link, locator)
      end

      ##
      #
      # Find a button on the page. The link can be found by its id, name or value.
      #
      # @param [String] locator       Which button to find
      # @return [Capybara::Element]   The found element
      #
      def find_button(locator)
        find(:button, locator)
      end

      ##
      #
      # Find a element on the page, given its id.
      #
      # @param [String] locator       Which element to find
      # @return [Capybara::Element]   The found element
      #
      def find_by_id(id)
        find(:id, id)
      end

      ##
      #
      # Find all elements on the page matching the given selector
      # and options.
      #
      # Both XPath and CSS expressions are supported, but Capybara
      # does not try to automatically distinguish between them. The
      # following statements are equivalent:
      #
      #     page.all(:css, 'a#person_123')
      #     page.all(:xpath, '//a[@id="person_123"]')
      #
      #
      # If the type of selector is left out, Capybara uses
      # {Capybara.default_selector}. It's set to :css by default.
      #
      #     page.all("a#person_123")
      #
      #     Capybara.default_selector = :xpath
      #     page.all('//a[@id="person_123"]')
      #
      # The set of found elements can further be restricted by specifying
      # options. It's possible to select elements by their text or visibility:
      #
      #     page.all('a', :text => 'Home')
      #     page.all('#menu li', :visible => true)
      #
      # @overload all([kind], locator, options)
      #   @param [:css, :xpath] kind                 The type of selector
      #   @param [String] locator                    The selector
      #   @option options [String, Regexp] text      Only find elements which contain this text or match this regexp
      #   @option options [Boolean] visible          Only find elements that are visible on the page. Setting this to false
      #                                              (the default, unless Capybara.ignore_hidden_elements = true), finds
      #                                              invisible _and_ visible elements.
      # @return [Array[Capybara::Element]]           The found elements
      #
      def all(*args)
        args, options = extract_normalized_options(args)

        selector = Capybara::Selector.normalize(*args)
        selector.xpaths.
          map    { |path| find_in_base(selector, path) }.flatten.
          select { |node| selector.matches_filters?(node) }
      end

      ##
      #
      # Find the first element on the page matching the given selector
      # and options, or nil if no element matches.
      #
      # When only the first matching element is needed, this method can
      # be faster than all(*args).first.
      #
      # @overload first([kind], locator, options)
      #   @param [:css, :xpath] kind                 The type of selector
      #   @param [String] locator                    The selector
      #   @param [Hash] options                      Additional options; see {all}
      # @return [Capybara::Element]                  The found element or nil
      #
      def first(*args)
        args, options  = extract_normalized_options(args)
        found_elements = []

        selector = Capybara::Selector.normalize(*args)
        selector.xpaths.each do |path|
          find_in_base(selector, path).each do |node|
            if selector.matches_filters?(node)
              found_elements << node
              return found_elements.last if not Capybara.prefer_visible_elements or node.visible?
            end
          end
        end
        found_elements.first
      end

    protected

      def raise_find_error(*args)
        args, options = extract_normalized_options(args)
        normalized    = Capybara::Selector.normalize(*args)
        message       = options[:message] || "Unable to find #{normalized.name} #{normalized.locator.inspect}"
        message       = normalized.failure_message.call(self, normalized) if normalized.failure_message

        raise Capybara::ElementNotFound, message
      end

      def find_in_base(selector, xpath)
        base.find(xpath).map do |node|
          Capybara::Node::Element.new(session, node, self, selector)
        end
      end

      def extract_normalized_options(args)
        options = if args.last.is_a?(Hash) then args.pop.dup else {} end

        if text = options[:text]
          options[:text] = Regexp.escape(text) unless text.kind_of?(Regexp)
        end

        if !options.has_key?(:visible)
          options[:visible] = Capybara.ignore_hidden_elements
        end

        if selected = options[:selected]
          options[:selected] = [selected].flatten
        end

        [args.push(options), options]
      end

    end
  end
end
