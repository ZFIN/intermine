require 'rubygems'
require 'rest-open-uri'
require 'intermine/model'
require "intermine/query"
require "intermine/lists"
require "rexml/document"
require "forwardable"

class Service

    extend Forwardable

    VERSION_PATH = "/version"
    MODEL_PATH = "/model/json"
    TEMPLATES_PATH = "/templates"
    QUERY_RESULTS_PATH = "/query/results"
    TEMPLATE_RESULTS_PATH = "/template/results"
    LISTS_PATH = "/lists/json"

    attr_reader :version, :root, :token, :broken_templates

    def_delegators :@list_manager, :lists, :list

    def initialize(root, token=nil, mock_model=nil)
        @root = root
        @token = token
        begin
            @version = fetch(@root + VERSION_PATH).to_i
        rescue => e
            raise ServiceError, "Error fetching version at #{@root + VERSION_PATH}: #{e.message}"
        end
        @model = mock_model
        @_templates = nil
        @broken_templates = []
        @list_manager = Lists::ListManager.new(self)
    end

    def model
        if @model.nil?
            data = fetch(@root + MODEL_PATH)
            @model = Model.new(data, self)
        end
        @model
    end

    def new_query(rootClass=nil)
        return PathQuery::Query.new(self.model, rootClass, self)
    end

    alias query new_query

    def template(name) 
        return templates[name]
    end

    def templates 
        if @_templates.nil?
            @_templates = {}
            parser = PathQuery::Template.parser(model)
            template_xml = fetch(@root + TEMPLATES_PATH)
            doc = REXML::Document.new(template_xml)
            doc.elements.each("template-queries/template") do |t|
                begin
                    temp = parser.parse(t)
                    @_templates[temp.name] = temp
                rescue
                    @broken_templates.push(t.attribute("name").value)
                end
            end
        end
        return @_templates
    end

    def template_names
        return templates.keys.sort
    end

    def get_list_data
        return fetch(@root + LISTS_PATH)
    end

    private

    def prepare_uri(url)
        uri = URI(url)
        if uri.query
            uri.query += "&token=#{@token}" if @token
        else
            uri.query = "token=#{@token}" if @token
        end
        return uri
    end

    def fetch(url)
        uri = prepare_uri(url)
        return uri.open.read
    end
end

class ServiceError < RuntimeError
end
