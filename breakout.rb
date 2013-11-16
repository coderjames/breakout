#!/usr/bin/env ruby
require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
include Gosu

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768
PADDLE_SPEED = 5
BALL_SPEED = 5
BALL_INITIAL_X = 60
BALL_INITIAL_Y = 300
PLAYER_STARTING_LIVES = 3

DEMO_MODE = true

class Game < Chingu::Window
  def initialize
    super(SCREEN_WIDTH,SCREEN_HEIGHT)              # leave it blank and it will be 800,600,non fullscreen
    self.input = { :escape => :exit } # exits game on Escape

    @player = Player.create(:x => SCREEN_WIDTH / 2, :y => 700, :image => Image["paddle.png"])
    @player_score = 0
    @player_score_text = Chingu::Text.create("Score  #{@player_score}", :x => 5, :y => 5, :size => 20, :color => ::Gosu::Color::WHITE)
    @player_lives_text = Chingu::Text.create("Lives #{@player.lives}", :x => 500, :y => 5, :size => 20, :color => ::Gosu::Color::WHITE)

    @ball = Ball.create(:image => Image["ball.png"])

    @brick_images = [ Image["blue_brick.png"], Image["green_brick.png"], Image["pink_brick.png"], Image["yellow_brick.png"] ]
    reset_level
  end

  def reset_level
    @bricks = []
    for y in (1..5)
      for x in (1..13)
        @bricks.push( Brick.create(:x => (x * 75) - 15, :y => (y * 30) + 5, :image => @brick_images[ y % 4 ], :factor => 1.5) )
      end
    end
  end

  def update
    super
    #self.caption = "FPS: #{self.fps} milliseconds_since_last_tick: #{self.milliseconds_since_last_tick}"

    if DEMO_MODE == true then
      if @ball.x < @player.x
        @player.move_left
      end

      if @ball.x > @player.x
        @player.move_right
      end
    end

    Player.each_collision(Ball) do |plr, bal|
      @ball.y_velocity = -@ball.y_velocity
      Sound["bounce_off_paddle.wav"].play(0.1)
    end

    Ball.each_collision(Brick) do |bal, brk|
      # TODO: Only use the below code for when the ball hits the top or bottom of a brick.
      #       If the ball hits the side of a brick, flip the sign of the x_velocity instead.
      @ball.y_velocity = -@ball.y_velocity

      @player_score += 2
      @bricks.delete(brk)
      brk.destroy
      Sound["hit_a_brick.wav"].play(0.1)
      @player_score_text.text = "Score  #{@player_score}"

      reset_level if @bricks.empty?
      break
    end

    # player missed the ball?
    if @ball.y >= SCREEN_HEIGHT then
      Sound["lost_a_life.wav"].play(0.1)
      @player.lives -= 1
      if @player.lives <= 0 then
        exit
      end
      @ball.reset
      @player_lives_text.text = "Lives #{@player.lives}"
    end
  end
end

class Player < Chingu::GameObject
  trait :bounding_box
  traits :collision_detection

  attr_accessor :lives;

  def initialize(options)
    super(options)
    self.input = { [:holding_left] => :move_left,
                   [:holding_right] => :move_right,
    }
    cache_bounding_box
    @lives = PLAYER_STARTING_LIVES
  end

  def move_left
    @x -= PADDLE_SPEED;
    if (@x - (@image.width / 2)) < 0 then
      @x = (@image.width / 2)
    end
  end

  def move_right
    @x += PADDLE_SPEED;
    if (@x + (@image.width / 2)) > SCREEN_WIDTH then
      @x = SCREEN_WIDTH - (@image.width / 2)
    end
  end
end

class Ball < Chingu::GameObject
  trait :bounding_box
  traits :collision_detection

  attr_accessor :y_velocity;

  def initialize(options)
    super(options)
    cache_bounding_box
    reset
  end

  def reset
    @x = BALL_INITIAL_X;
    @x_velocity = BALL_SPEED

    @y = BALL_INITIAL_Y;
    @y_velocity = BALL_SPEED
  end

  def update
    @x += @x_velocity;
    @y += @y_velocity;

    # bounce off the left and ride sides of the screen
    if ((@x - (@image.width / 2)) < 0) or ((@x + (@image.width / 2)) > SCREEN_WIDTH) then
      @x_velocity = -@x_velocity
      Sound["bounce_off_paddle.wav"].play(0.1)
    end

    # bounce off the top and bottom sides of the screen
    #if ((@y - (@image.width / 2)) < 0) or ((@y + (@image.width / 2)) > SCREEN_HEIGHT) then
    # bounce off the top of the screen
    if @y - (@image.width / 2) < 0 then
      @y_velocity = -@y_velocity
      Sound["bounce_off_paddle.wav"].play(0.1)
    end
  end
end

class Brick < Chingu::GameObject
  trait :bounding_box
  traits :collision_detection

  def initialize(options)
    super(options)
    cache_bounding_box
  end
end


Game.new.show
