/*==============================================================================
  ECON 580 Thesis — Global Settings

  Purpose: Define all project paths and graph formatting defaults.
           Run this at the top of every .do file.

  Usage:   do "${code}/globals.do"   (or run from 00_master.do)
==============================================================================*/

clear all
set more off
set varabbrev off

* --- Project root ---
* IMPORTANT: Change this one line when moving to a different machine.
global root "/Users/alexdelatorre/Desktop/econ580-thesis"

* --- Directory globals ---
global code      "${root}/code/stata"
global data      "${root}/data/event_study"
global dtapath   "${root}/data/event_study/stata"
global figures   "${root}/output/figures/stata"
global tables    "${root}/output/tables/stata"
global logs      "${root}/logs"
global statalogs "${root}/logs/stata"

* --- Graph defaults ---
set scheme s2color
graph set window fontface "Times New Roman"

* --- Key policy dates ---
global pdufa_year        = 1992
global hatchwaxman_year  = 1984

* --- Sample restrictions ---
* First full year of PDUFA implementation
global pdufa_first_full_year = 1993
* Last fully observed year in the March 2026 extract
global last_full_year = 2025
