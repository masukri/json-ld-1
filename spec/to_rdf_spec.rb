# coding: utf-8
require_relative 'spec_helper'

describe JSON::LD::API do
  let(:logger) {RDF::Spec.logger}

  context ".toRdf" do
    it "should implement RDF::Enumerable" do
      expect(JSON::LD::API.toRdf({})).to be_a(RDF::Enumerable)
    end

    context "unnamed nodes" do
      {
        "no @id" => [
          %q({
            "http://example.com/foo": "bar"
          }),
          %q([ <http://example.com/foo> "bar"^^xsd:string] .)
        ],
        "@id with _:a" => [
          %q({
            "@id": "_:a",
            "http://example.com/foo": "bar"
          }),
          %q([ <http://example.com/foo> "bar"^^xsd:string] .)
        ],
        "@id with _:a and reference" => [
          %q({
            "@id": "_:a",
            "http://example.com/foo": {"@id": "_:a"}
          }),
          %q(_:a <http://example.com/foo> _:a .)
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "nodes with @id" do
      {
        "with IRI" => [
          %q({
            "@id": "http://example.com/a",
            "http://example.com/foo": "bar"
          }),
          %q(<http://example.com/a> <http://example.com/foo> "bar" .)
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
      
      context "with relative IRIs" do
        {
          "base" => [
            %({
              "@id": "",
              "@type": "#{RDF::RDFS.Resource}"
            }),
            %(<http://example.org/> a <#{RDF::RDFS.Resource}> .)
          ],
          "relative" => [
            %({
              "@id": "a/b",
              "@type": "#{RDF::RDFS.Resource}"
            }),
            %(<http://example.org/a/b> a <#{RDF::RDFS.Resource}> .)
          ],
          "hash" => [
            %({
              "@id": "#a",
              "@type": "#{RDF::RDFS.Resource}"
            }),
            %(<http://example.org/#a> a <#{RDF::RDFS.Resource}> .)
          ],
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, base: "http://example.org/")).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end
    end

    context "typed nodes" do
      {
        "one type" => [
          %q({
            "@type": "http://example.com/foo"
          }),
          %q([ a <http://example.com/foo> ] .)
        ],
        "two types" => [
          %q({
            "@type": ["http://example.com/foo", "http://example.com/baz"]
          }),
          %q([ a <http://example.com/foo>, <http://example.com/baz> ] .)
        ],
        "blank node type" => [
          %q({
            "@type": "_:foo"
          }),
          %q([ a _:foo ] .)
        ]
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "key/value" do
      {
        "string" => [
          %q({
            "http://example.com/foo": "bar"
          }),
          %q([ <http://example.com/foo> "bar"^^xsd:string ] .)
        ],
        "strings" => [
          %q({
            "http://example.com/foo": ["bar", "baz"]
          }),
          %q([ <http://example.com/foo> "bar"^^xsd:string, "baz"^^xsd:string ] .)
        ],
        "IRI" => [
          %q({
            "http://example.com/foo": {"@id": "http://example.com/bar"}
          }),
          %q([ <http://example.com/foo> <http://example.com/bar> ] .)
        ],
        "IRIs" => [
          %q({
            "http://example.com/foo": [{"@id": "http://example.com/bar"}, {"@id": "http://example.com/baz"}]
          }),
          %q([ <http://example.com/foo> <http://example.com/bar>, <http://example.com/baz> ] .)
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "literals" do
      {
        "plain literal" =>
        [
          %q({"@id": "http://greggkellogg.net/foaf#me", "http://xmlns.com/foaf/0.1/name": "Gregg Kellogg"}),
          %q(<http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg" .)
        ],
        "explicit plain literal" =>
        [
          %q({"http://xmlns.com/foaf/0.1/name": {"@value": "Gregg Kellogg"}}),
          %q(_:a <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg"^^xsd:string .)
        ],
        "language tagged literal" =>
        [
          %q({"http://www.w3.org/2000/01/rdf-schema#label": {"@value": "A plain literal with a lang tag.", "@language": "en-us"}}),
          %q(_:a <http://www.w3.org/2000/01/rdf-schema#label> "A plain literal with a lang tag."@en-us .)
        ],
        "I18N literal with language" =>
        [
          %q([{
            "@id": "http://greggkellogg.net/foaf#me",
            "http://xmlns.com/foaf/0.1/knows": {"@id": "http://www.ivan-herman.net/foaf#me"}
          },{
            "@id": "http://www.ivan-herman.net/foaf#me",
            "http://xmlns.com/foaf/0.1/name": {"@value": "Herman Iván", "@language": "hu"}
          }]),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.net/foaf#me> .
            <http://www.ivan-herman.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Herman Iv\u00E1n"@hu .
          )
        ],
        "explicit datatyped literal" =>
        [
          %q({
            "@id":  "http://greggkellogg.net/foaf#me",
            "http://purl.org/dc/terms/created":  {"@value": "1957-02-27", "@type": "http://www.w3.org/2001/XMLSchema#date"}
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://purl.org/dc/terms/created> "1957-02-27"^^<http://www.w3.org/2001/XMLSchema#date> .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end

      context "with @type: @json" do
        {
          "true": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#bool", "@type": "@json"}
              },
              "e": true
            }),
            output:%(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:bool "true"^^rdf:JSON] .
            )
          },
          "false": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#bool", "@type": "@json"}
              },
              "e": false
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:bool "false"^^rdf:JSON] .
            )
          },
          "double": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#double", "@type": "@json"}
              },
              "e": 1.23
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:double "1.23"^^rdf:JSON] .
            )
          },
          "double-zero": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#double", "@type": "@json"}
              },
              "e": 0
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:double "0"^^rdf:JSON] .
            )
          },
          "integer": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#integer", "@type": "@json"}
              },
              "e": 123
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:integer "123"^^rdf:JSON] .
            )
          },
          "string": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#string", "@type": "@json"}
              },
              "e": "string"
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:string "\\"string\\""^^rdf:JSON] .
            )
          },
          "null": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#null", "@type": "@json"}
              },
              "e": null
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:null "null"^^rdf:JSON] .
            )
          },
          "object": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#object", "@type": "@json"}
              },
              "e": {"foo": "bar"}
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:object """{"foo":"bar"}"""^^rdf:JSON] .
            )
          },
          "array": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#array", "@type": "@json"}
              },
              "e": [{"foo": "bar"}]
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:array """[{"foo":"bar"}]"""^^rdf:JSON] .
            )
          },
          "c14n-arrays": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#c14n", "@type": "@json"}
              },
              "e": [
                56,
                {
                  "d": true,
                  "10": null,
                  "1": [ ]
                }
              ]
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """[56,{"1":[],"10":null,"d":true}]"""^^rdf:JSON] .
            )
          },
          "c14n-french": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#c14n", "@type": "@json"}
              },
              "e": {
                "peach": "This sorting order",
                "péché": "is wrong according to French",
                "pêche": "but canonicalization MUST",
                "sin":   "ignore locale"
              }
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"peach":"This sorting order","péché":"is wrong according to French","pêche":"but canonicalization MUST","sin":"ignore locale"}"""^^rdf:JSON] .
            )
          },
          "c14n-structures": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#c14n", "@type": "@json"}
              },
              "e": {
                "1": {"f": {"f": "hi","F": 5} ," ": 56.0},
                "10": { },
                "": "empty",
                "a": { },
                "111": [ {"e": "yes","E": "no" } ],
                "A": { }
              }
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"":"empty","1":{" ":56,"f":{"F":5,"f":"hi"}},"10":{},"111":[{"E":"no","e":"yes"}],"A":{},"a":{}}"""^^rdf:JSON] .
            )
          },
          "c14n-unicode": {
            input: %({
              "@context": {
                "@version": 1.1,
                "e": {"@id": "http://example.org/vocab#c14n", "@type": "@json"}
              },
              "e": {
                "Unnormalized Unicode":"A\u030a"
              }
            }),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"Unnormalized Unicode":"Å"}"""^^rdf:JSON] .
            )
          },
        }.each do |title, params|
          it title do
            params[:output] = RDF::Graph.new << RDF::Turtle::Reader.new(params[:output])
            run_to_rdf params
          end
        end
      end
    end

    context "prefixes" do
      {
        "empty suffix" => [
          %q({"@context": {"prefix": "http://example.com/default#"}, "prefix:": "bar"}),
          %q(_:a <http://example.com/default#> "bar"^^xsd:string .)
        ],
        "prefix:suffix" => [
          %q({"@context": {"prefix": "http://example.com/default#"}, "prefix:foo": "bar"}),
          %q(_:a <http://example.com/default#foo> "bar"^^xsd:string .)
        ]
      }.each_pair do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "overriding keywords" do
      {
        "'url' for @id, 'a' for @type" => [
          %q({
            "@context": {"url": "@id", "a": "@type", "name": "http://schema.org/name"},
            "url": "http://example.com/about#gregg",
            "a": "http://schema.org/Person",
            "name": "Gregg Kellogg"
          }),
          %q(
            <http://example.com/about#gregg> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://schema.org/Person> .
            <http://example.com/about#gregg> <http://schema.org/name> "Gregg Kellogg"^^xsd:string .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "chaining" do
      {
        "explicit subject" =>
        [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": {
              "@id": "http://www.ivan-herman.net/foaf#me",
              "foaf:name": "Ivan Herman"
            }
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.net/foaf#me> .
            <http://www.ivan-herman.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Ivan Herman" .
          )
        ],
        "implicit subject" =>
        [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": {
              "foaf:name": "Manu Sporny"
            }
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://xmlns.com/foaf/0.1/name> "Manu Sporny"^^xsd:string .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "multiple values" do
      {
        "literals" =>
        [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": ["Manu Sporny", "Ivan Herman"]
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> "Manu Sporny" .
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> "Ivan Herman" .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "lists" do
      {
        "Empty" => [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": {"@list": []}
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          )
        ],
        "single value" => [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": {"@list": ["Manu Sporny"]}
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Manu Sporny"^^xsd:string .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          )
        ],
        "single value (with coercion)" => [
          %q({
            "@context": {
              "foaf": "http://xmlns.com/foaf/0.1/",
              "foaf:knows": { "@container": "@list"}
            },
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": ["Manu Sporny"]
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Manu Sporny"^^xsd:string .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          )
        ],
        "multiple values" => [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@id": "http://greggkellogg.net/foaf#me",
            "foaf:knows": {"@list": ["Manu Sporny", "Dave Longley"]}
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Manu Sporny"^^xsd:string .
            _:a <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:b .
            _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Dave Longley"^^xsd:string .
            _:b <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> .
          )
        ],
        "@list containing @list" => [
          %q({
            "@id": "http://example/A",
            "http://example.com/foo": {"@list": [{"@list": ["baz"]}]}
          }),
          %q(
            <http://example/A> <http://example.com/foo> (("baz")) .
          )
        ],
        "@list containing empty @list" => [
          %({
            "@id": "http://example/A",
            "http://example.com/foo": {"@list": [{"@list": []}]}
          }),
          %q(
            <http://example/A> <http://example.com/foo> (()) .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "context" do
      {
        "@id coersion" =>
        [
          %q({
            "@context": {
              "knows": {"@id": "http://xmlns.com/foaf/0.1/knows", "@type": "@id"}
            },
            "@id":  "http://greggkellogg.net/foaf#me",
            "knows":  "http://www.ivan-herman.net/foaf#me"
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.net/foaf#me> .
          )
        ],
        "datatype coersion" =>
        [
          %q({
            "@context": {
              "dcterms":  "http://purl.org/dc/terms/",
              "xsd":      "http://www.w3.org/2001/XMLSchema#",
              "created":  {"@id": "http://purl.org/dc/terms/created", "@type": "xsd:date"}
            },
            "@id":  "http://greggkellogg.net/foaf#me",
            "created":  "1957-02-27"
          }),
          %q(
            <http://greggkellogg.net/foaf#me> <http://purl.org/dc/terms/created> "1957-02-27"^^<http://www.w3.org/2001/XMLSchema#date> .
          )
        ],
        "sub-objects with context" => [
          %q({
            "@context": {"foo": "http://example.com/foo"},
            "foo":  {
              "@context": {"foo": "http://example.org/foo"},
              "foo": "bar"
            }
          }),
          %q(
            _:a <http://example.com/foo> _:b .
            _:b <http://example.org/foo> "bar"^^xsd:string .
          )
        ],
        "contexts with a list processed in order" => [
          %q({
            "@context": [
              {"foo": "http://example.com/foo"},
              {"foo": "http://example.org/foo"}
            ],
            "foo":  "bar"
          }),
          %q(
            _:b <http://example.org/foo> "bar"^^xsd:string .
          )
        ],
        "term definition resolves term as IRI" => [
          %q({
            "@context": [
              {"foo": "http://example.com/foo"},
              {"bar": "foo"}
            ],
            "bar":  "bar"
          }),
          %q(
            _:b <http://example.com/foo> "bar"^^xsd:string .
          )
        ],
        "term definition resolves prefix as IRI" => [
          %q({
            "@context": [
              {"foo": "http://example.com/foo#"},
              {"bar": "foo:bar"}
            ],
            "bar":  "bar"
          }),
          %q(
            _:b <http://example.com/foo#bar> "bar"^^xsd:string .
          )
        ],
        "@language" => [
          %q({
            "@context": {
              "foo": "http://example.com/foo#",
              "@language": "en"
            },
            "foo:bar":  "baz"
          }),
          %q(
            _:a <http://example.com/foo#bar> "baz"@en .
          )
        ],
        "@language with override" => [
          %q({
            "@context": {
              "foo": "http://example.com/foo#",
              "@language": "en"
            },
            "foo:bar":  {"@value": "baz", "@language": "fr"}
          }),
          %q(
            _:a <http://example.com/foo#bar> "baz"@fr .
          )
        ],
        "@language with plain" => [
          %q({
            "@context": {
              "foo": "http://example.com/foo#",
              "@language": "en"
            },
            "foo:bar":  {"@value": "baz"}
          }),
          %q(
            _:a <http://example.com/foo#bar> "baz"^^xsd:string .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, base: "http://example/", logger: logger, inputDocument: js)
        end
      end
      
      context "coercion" do
        context "term def with @id + @type" do
          {
            "dt with term" => [
              %q({
                "@context": [
                  {"date": "http://www.w3.org/2001/XMLSchema#date", "term": "http://example.org/foo#"},
                  {"foo": {"@id": "term", "@type": "date"}}
                ],
                "foo": "bar"
              }),
              %q(
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
                [ <http://example.org/foo#> "bar"^^xsd:date ] .
              )
            ],
            "@id with term" => [
              %q({
                "@context": [
                  {"foo": {"@id": "http://example.org/foo#bar", "@type": "@id"}}
                ],
                "foo": "http://example.org/foo#bar"
              }),
              %q(
                _:a <http://example.org/foo#bar> <http://example.org/foo#bar> .
              )
            ],
            "coercion without term definition" => [
              %q({
                "@context": [
                  {
                    "xsd": "http://www.w3.org/2001/XMLSchema#",
                    "dc": "http://purl.org/dc/terms/"
                  },
                  {
                    "dc:date": {"@type": "xsd:date"}
                  }
                ],
                "dc:date": "2011-11-23"
              }),
              %q(
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
                @prefix dc: <http://purl.org/dc/terms/> .
                [ dc:date "2011-11-23"^^xsd:date] .
              )
            ],
          }.each do |title, (js, ttl)|
            it title do
              ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
              expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
            end
          end
        end
      end

      context "lists" do
        context "term def with @id + @type + @container" do
          {
            "dt with term" => [
              %q({
                "@context": [
                  {"date": "http://www.w3.org/2001/XMLSchema#date", "term": "http://example.org/foo#"},
                  {"foo": {"@id": "term", "@type": "date", "@container": "@list"}}
                ],
                "foo": ["bar"]
              }),
              %q(
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
                [ <http://example.org/foo#> ("bar"^^xsd:date) ] .
              )
            ],
            "@id with term" => [
              %q({
                "@context": [
                  {"foo": {"@id": "http://example.org/foo#bar", "@type": "@id", "@container": "@list"}}
                ],
                "foo": ["http://example.org/foo#bar"]
              }),
              %q(
                _:a <http://example.org/foo#bar> (<http://example.org/foo#bar>) .
              )
            ],
          }.each do |title, (js, ttl)|
            it title do
              ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
              expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
            end
          end
        end
      end
    end

    context "blank node predicates" do
      subject {%q({"@id": "http://example/subj", "_:foo": "bar"})}

      it "outputs statements with blank node predicates if :produceGeneralizedRdf is true" do
        expect do
          graph = parse(subject, produceGeneralizedRdf: true)
          expect(graph.count).to eq 1
        end.to write("[DEPRECATION]").to(:error)
      end

      it "rejects statements with blank node predicates if :produceGeneralizedRdf is false" do
        expect do
          graph = parse(subject, produceGeneralizedRdf: false)
          expect(graph.count).to eq 0
        end.to write("[DEPRECATION]").to(:error)
      end
    end

    context "@included" do
      {
        "Basic Included array": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/"
            },
            "prop": "value",
            "@included": [{
              "prop": "value2"
            }]
          }),
          output: %(
            [<http://example.org/prop> "value"] .
            [<http://example.org/prop> "value2"] .
          )
        },
        "Basic Included object": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/"
            },
            "prop": "value",
            "@included": {
              "prop": "value2"
            }
          }),
          output: %(
            [<http://example.org/prop> "value"] .
            [<http://example.org/prop> "value2"] .
          )
        },
        "Multiple properties mapping to @included are folded together": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/",
              "included1": "@included",
              "included2": "@included"
            },
            "included1": {"prop": "value1"},
            "included2": {"prop": "value2"}
          }),
          output: %(
            [<http://example.org/prop> "value1"] .
            [<http://example.org/prop> "value2"] .
          )
        },
        "Included containing @included": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/"
            },
            "prop": "value",
            "@included": {
              "prop": "value2",
              "@included": {
                "prop": "value3"
              }
            }
          }),
          output: %(
            [<http://example.org/prop> "value"] .

            [<http://example.org/prop> "value2"] .

            [<http://example.org/prop> "value3"] .
          )
        },
        "Property value with @included": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/"
            },
            "prop": {
              "@type": "Foo",
              "@included": {
                "@type": "Bar"
              }
            }
          }),
          output: %(
            [<http://example.org/prop> [a <http://example.org/Foo>]] .
            [a <http://example.org/Bar>] .
          )
        },
        "json.api example": {
          input: %({
            "@context": {
              "@version": 1.1,
              "@vocab": "http://example.org/vocab#",
              "@base": "http://example.org/base/",
              "id": "@id",
              "type": "@type",
              "data": "@nest",
              "attributes": "@nest",
              "links": "@nest",
              "relationships": "@nest",
              "included": "@included",
              "self": {"@type": "@id"},
              "related": {"@type": "@id"},
              "comments": {
                "@context": {
                  "data": null
                }
              }
            },
            "data": [{
              "type": "articles",
              "id": "1",
              "attributes": {
                "title": "JSON:API paints my bikeshed!"
              },
              "links": {
                "self": "http://example.com/articles/1"
              },
              "relationships": {
                "author": {
                  "links": {
                    "self": "http://example.com/articles/1/relationships/author",
                    "related": "http://example.com/articles/1/author"
                  },
                  "data": { "type": "people", "id": "9" }
                },
                "comments": {
                  "links": {
                    "self": "http://example.com/articles/1/relationships/comments",
                    "related": "http://example.com/articles/1/comments"
                  },
                  "data": [
                    { "type": "comments", "id": "5" },
                    { "type": "comments", "id": "12" }
                  ]
                }
              }
            }],
            "included": [{
              "type": "people",
              "id": "9",
              "attributes": {
                "first-name": "Dan",
                "last-name": "Gebhardt",
                "twitter": "dgeb"
              },
              "links": {
                "self": "http://example.com/people/9"
              }
            }, {
              "type": "comments",
              "id": "5",
              "attributes": {
                "body": "First!"
              },
              "relationships": {
                "author": {
                  "data": { "type": "people", "id": "2" }
                }
              },
              "links": {
                "self": "http://example.com/comments/5"
              }
            }, {
              "type": "comments",
              "id": "12",
              "attributes": {
                "body": "I like XML better"
              },
              "relationships": {
                "author": {
                  "data": { "type": "people", "id": "9" }
                }
              },
              "links": {
                "self": "http://example.com/comments/12"
              }
            }]
          }),
          output: %(
          <http://example.org/base/1> a <http://example.org/vocab#articles>;
            <http://example.org/vocab#author> <http://example.org/base/9>;
            <http://example.org/vocab#comments> [
              <http://example.org/vocab#related> <http://example.com/articles/1/comments>;
              <http://example.org/vocab#self> <http://example.com/articles/1/relationships/comments>
            ];
            <http://example.org/vocab#self> <http://example.com/articles/1>;
            <http://example.org/vocab#title> "JSON:API paints my bikeshed!" .

          <http://example.org/base/12> a <http://example.org/vocab#comments>;
            <http://example.org/vocab#author> <http://example.org/base/9>;
            <http://example.org/vocab#body> "I like XML better";
            <http://example.org/vocab#self> <http://example.com/comments/12> .

          <http://example.org/base/5> a <http://example.org/vocab#comments>;
            <http://example.org/vocab#author> <http://example.org/base/2>;
            <http://example.org/vocab#body> "First!";
            <http://example.org/vocab#self> <http://example.com/comments/5> .

          <http://example.org/base/2> a <http://example.org/vocab#people> .

          <http://example.org/base/9> a <http://example.org/vocab#people>;
            <http://example.org/vocab#first-name> "Dan";
            <http://example.org/vocab#last-name> "Gebhardt";
            <http://example.org/vocab#related> <http://example.com/articles/1/author>;
            <http://example.org/vocab#self> <http://example.com/articles/1/relationships/author>,
              <http://example.com/people/9>;
            <http://example.org/vocab#twitter> "dgeb" .
          )
        },
      }.each do |title, params|
        it(title) {run_to_rdf params}
      end
    end

    context "advanced features" do
      {
        "number syntax (decimal)" =>
        [
          %q({"@context": { "measure": "http://example/measure#"}, "measure:cups": 5.3}),
          %q(_:a <http://example/measure#cups> "5.3E0"^^<http://www.w3.org/2001/XMLSchema#double> .)
        ],
        "number syntax (double)" =>
        [
          %q({"@context": { "measure": "http://example/measure#"}, "measure:cups": 5.3e0}),
          %q(_:a <http://example/measure#cups> "5.3E0"^^<http://www.w3.org/2001/XMLSchema#double> .)
        ],
        "number syntax (integer)" =>
        [
          %q({"@context": { "chem": "http://example/chem#"}, "chem:protons": 12}),
          %q(_:a <http://example/chem#protons> "12"^^<http://www.w3.org/2001/XMLSchema#integer> .)
        ],
        "boolan syntax" =>
        [
          %q({"@context": { "sensor": "http://example/sensor#"}, "sensor:active": true}),
          %q(_:a <http://example/sensor#active> "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .)
        ],
        "Array top element" =>
        [
          %q([
            {"@id":   "http://example.com/#me", "@type": "http://xmlns.com/foaf/0.1/Person"},
            {"@id":   "http://example.com/#you", "@type": "http://xmlns.com/foaf/0.1/Person"}
          ]),
          %q(
            <http://example.com/#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
            <http://example.com/#you> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
          )
        ],
        "@graph with array of objects value" =>
        [
          %q({
            "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
            "@graph": [
              {"@id":   "http://example.com/#me", "@type": "foaf:Person"},
              {"@id":   "http://example.com/#you", "@type": "foaf:Person"}
            ]
          }),
          %q(
            <http://example.com/#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
            <http://example.com/#you> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
          )
        ],
        "XMLLiteral" => [
          %q({
            "http://rdfs.org/sioc/ns#content": {
              "@value": "foo",
              "@type": "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
            }
          }),
          %q(
            [<http://rdfs.org/sioc/ns#content> "foo"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>] .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "@direction" do
      context "rdfDirection: null" do
        {
          "no language rtl": [
            %q({"http://example.org/label": {"@value": "no language", "@direction": "rtl"}}),
            %q(_:a <http://example.org/label> "no language" .)
          ],
          "en-US rtl": [
            %q({"http://example.org/label": {"@value": "en-US", "@language": "en-US", "@direction": "rtl"}}),
            %q(_:a <http://example.org/label> "en-US"@en-us .)
          ]
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, rdfDirection: nil)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end

      context "rdfDirection: i18n-datatype" do
        {
          "no language rtl": [
            %q({"http://example.org/label": {"@value": "no language", "@direction": "rtl"}}),
            %q(_:a <http://example.org/label> "no language"^^<https://www.w3.org/ns/i18n#_rtl> .)
          ],
          "en-US rtl": [
            %q({"http://example.org/label": {"@value": "en-US", "@language": "en-US", "@direction": "rtl"}}),
            %q(_:a <http://example.org/label> "en-US"^^<https://www.w3.org/ns/i18n#en-us_rtl> .)
          ]
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, rdfDirection: 'i18n-datatype')).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end

      context "rdfDirection: compound-literal" do
        {
          "no language rtl": [
            %q({"http://example.org/label": {"@value": "no language", "@direction": "rtl"}}),
            %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              _:a <http://example.org/label> [
                rdf:value "no language";
                rdf:direction "rtl"
              ] .
            )
          ],
          "en-US rtl": [
            %q({"http://example.org/label": {"@value": "en-US", "@language": "en-US", "@direction": "rtl"}}),
            %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              _:a <http://example.org/label> [
                rdf:value "en-US";
                rdf:language "en-us";
                rdf:direction "rtl"
              ] .
            )
          ]
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, rdfDirection: 'compound-literal')).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end
    end

    context "exceptions" do
      {
        "Invalid subject" => {
          input: %({
            "@id": "http://example.com/a b",
            "http://example.com/foo": "bar"
          }),
          output: %()
        },
        "Invalid predicate" => {
          input: %({
            "@id": "http://example.com/foo",
            "http://example.com/a b": "bar"
          }),
          output: %()
        },
        "Invalid object" => {
          input: %({
            "@id": "http://example.com/foo",
            "http://example.com/bar": {"@id": "http://example.com/baz z"}
          }),
          output: %()
        },
        "Invalid type" => {
          input: %({
            "@id": "http://example.com/foo",
            "@type": ["http://example.com/bar", "relative"]
          }),
          output: %(<http://example.com/foo> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.com/bar> .)
        },
        "Invalid language" => {
          input: %({
            "@id": "http://example.com/foo",
            "http://example.com/bar": {"@value": "bar", "@language": "a b"}
          }),
          output: %(),
          write: "@language must be valid BCP47"
        },
        "Invalid datatype" => {
          input: %({
            "@id": "http://example.com/foo",
            "http://example.com/bar": {"@value": "bar", "@type": "http://example.com/baz z"}
          }),
          exception: JSON::LD::JsonLdError::InvalidTypedValue
        },
        "Injected IRIs check" => {
          input: %({
            "@id": "http://foo/> <http://bar/> <http://baz> .\n<data:little> <data:bobby> <data:tables> .\n<data:in-ur-base",
            "http://killin/#yer": "dudes"
          }),
          output: %(),
          pending: "jruby"
        },
      }.each do |title, params|
        it(title) do
          pending params[:pending] if params[:pending] == RUBY_ENGINE
          run_to_rdf params
        end
      end
    end
  end

  context "html" do
    {
      "Transforms embedded JSON-LD script element": {
        input: %(
        <html>
          <head>
            <script type="application/ld+json">
            {
              "@context": {
                "foo": {"@id": "http://example.com/foo", "@container": "@list"}
              },
              "foo": [{"@value": "bar"}]
            }
            </script>
          </head>
        </html>),
        output: %([ <http://example.com/foo> ( "bar")] .)
      },
      "Transforms first script element with extractAllScripts: false": {
        input: %(
        <html>
          <head>
            <script type="application/ld+json">
            {
              "@context": {
                "foo": {"@id": "http://example.com/foo", "@container": "@list"}
              },
              "foo": [{"@value": "bar"}]
            }
            </script>
            <script type="application/ld+json">
            {
              "@context": {"ex": "http://example.com/"},
              "@graph": [
                {"ex:foo": {"@value": "foo"}},
                {"ex:bar": {"@value": "bar"}}
              ]
            }
            </script>
          </head>
        </html>),
        output: %([ <http://example.com/foo> ( "bar")] .),
        extractAllScripts: false
      },
      "Transforms targeted script element": {
        input: %(
        <html>
          <head>
            <script id="first" type="application/ld+json">
            {
              "@context": {
                "foo": {"@id": "http://example.com/foo", "@container": "@list"}
              },
              "foo": [{"@value": "bar"}]
            }
            </script>
            <script id="second" type="application/ld+json">
            {
              "@context": {"ex": "http://example.com/"},
              "@graph": [
                {"ex:foo": {"@value": "foo"}},
                {"ex:bar": {"@value": "bar"}}
              ]
            }
            </script>
          </head>
        </html>),
        output: %(
          [ <http://example.com/foo> "foo"] .
          [ <http://example.com/bar> "bar"] .
        ),
        base: "http://example.org/doc#second"
      },
    }.each do |title, params|
      it(title) do
        params[:input] = StringIO.new(params[:input])
        params[:input].send(:define_singleton_method, :content_type) {"text/html"}
        run_to_rdf params.merge(validate: true)
      end
    end
  end

  def parse(input, **options)
    graph = options[:graph] || RDF::Graph.new
    options = {logger: logger, validate: true, canonicalize: false}.merge(options)
    JSON::LD::API.toRdf(StringIO.new(input), **options) {|st| graph << st}
    graph
  end

  def run_to_rdf(params)
    input, output = params[:input], params[:output]
    graph = params[:graph] || RDF::Graph.new
    input = StringIO.new(input) if input.is_a?(String)
    pending params.fetch(:pending, "test implementation") unless input
    if params[:exception]
      expect {JSON::LD::API.toRdf(input, **params)}.to raise_error(params[:exception])
    else
      if params[:write]
        expect{JSON::LD::API.toRdf(input, base: params[:base], logger: logger, **params) {|st| graph << st}}.to write(params[:write]).to(:error)
      else
        expect{JSON::LD::API.toRdf(input, base: params[:base], logger: logger, **params) {|st| graph << st}}.not_to write.to(:error)
      end
      expect(graph).to be_equivalent_graph(output, logger: logger, inputDocument: input)
    end
  end
end
