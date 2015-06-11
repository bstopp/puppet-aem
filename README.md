# adobe_experience_manager

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with adobe_experience_manager](#setup)
    * [What adobe_experience_manager affects](#what-adobe_experience_manager-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with adobe_experience_manager](#beginning-with-adobe_experience_manager)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs the Adobe Experience Manager (AEM) version of your choice into your vm, saving you from doing it manually.

## Module Description

This module installs AEM from the jar file you provide into the VM it sets up.  
It can support options for different users, directories, and versions.  It also supports deletion
but not upgrading as all versions of AEM aren't backwards compatable.  

## Setup

### What adobe_experience_manager affects

This will create or modify a directory of your choice in order to install AEM.


### Setup Requirements 

An AEM jar file is required for setup.

### Beginning with adobe_experience_manager

The very basic steps needed for a user to get the module up and running.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you may wish to include an additional section here: Upgrading
(For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

This module is still early on, as long as additions follow the overall flow and do not include an aem jar, they will be appriciated.


