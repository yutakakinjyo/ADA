# ADA

Operating support IRC Bot

## Install

### needs

- [redis](http://redis.io/)
- [ruby](https://www.ruby-lang.org/ja/)

```
$ git clone https://github.com/yutakakinjyo/ADA.git`
$ cd ADA
$ bundle install
$ cp .env.example .env
$ vi .env
```

## Running

```
$ ruby mother.rb
$ ruby ada.rb
```
## Stop

_mother_ and _ada_ is daemon.  
Please kill process from command line or menthion to bot e.g. `ADA: down`.

## Usage

### IRC Interface

list up events  
`event list`

add event  
`event add <event info>`

delete event  
`event delete <event info>`

ADA upgrade  
`ADA: 強くなれ`

### Reminder

**Time**  
ADA reminded you about added event when event info include `%H:%M`

**Date**  
ADA reminded you about added event when event info include `%m/%d`
