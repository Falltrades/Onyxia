#!/bin/bash

ps -ef | grep tsh | grep proxy | awk '{print $2}' | xargs sudo kill -9
