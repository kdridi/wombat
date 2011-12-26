require 'spec_helper'

describe EventCrawler::Crawler do
  before(:each) do
    @crawler = Class.new
    @parser = EventCrawler::Parser.new
    @crawler.send(:include, EventCrawler::Crawler)
    @crawler_instance = @crawler.new
    @crawler_instance.parser = @parser
  end

  it 'should call the provided block' do
    event_called = false
    
    @crawler.event { event_called = true }
    
    event_called.should be_true
  end

  it 'should provide metadata to yielded block' do
    @crawler.event do |e|
      e.should_not be_nil
    end 
  end

  it 'should store assigned metadata information' do
    time = Time.now

    @crawler.event do |e|
      e.title 'Fulltronic Dezembro'
      e.time Time.now
    end

    @crawler.venue { |v| v.name "Scooba" }
    @crawler.location { |v| v.latitude -50.2323 }

    @parser.should_receive(:parse) do |arg|
      arg.event_props.get_property("title").selector.should == "Fulltronic Dezembro"
      arg.event_props.get_property("time").selector.to_s.should == time.to_s
      arg.venue_props.get_property("name").selector.should == "Scooba"
      arg.location_props.get_property("latitude").selector.should == -50.2323
    end
    
    @crawler_instance.crawl
  end

  it 'should isolate metadata between different instances' do
    another_parser = EventCrawler::Parser.new
    another_crawler = Class.new
    another_crawler.send(:include, EventCrawler::Crawler)
    another_crawler_instance = another_crawler.new
    another_crawler_instance.parser = another_parser

    another_crawler.event { |e| e.title 'Ibiza' }
    another_parser.should_receive(:parse) { |arg| arg.event_props.get_property("title").selector.should == "Ibiza" }
    another_crawler_instance.crawl

    @crawler.event { |e| e.title 'Fulltronic Dezembro' }
    @parser.should_receive(:parse) { |arg| arg.event_props.get_property("title").selector.should == "Fulltronic Dezembro" }
    @crawler_instance.crawl
  end

  it 'should be able to assign arbitrary plain text metadata' do
    @crawler.some_data "/event/list"
    @parser.should_receive(:parse) { |arg| arg.some_data.should == "/event/list" }
    @crawler_instance.crawl
  end

  it 'should not explode if no block given' do
    @crawler.event
  end
end