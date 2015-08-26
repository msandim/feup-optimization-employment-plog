# Employee hiring optimization solution

This repository contains a solution to an employee hiring optimization problem using Constraint Logic Programming, developed on the "Logic Programming" course at FEUP. The development plataform used was Sicstus Prolog 4.3.0, along with the "clpfd" library for Constraint Logic Programming in Prolog.

This project was developed by [JPMMaia](https://github.com/JPMMaia) and [msandim](https://github.com/msandim).

For further information on the topics of this project, check the [report](https://github.com/msandim/optimization-employment-plog/raw/master/resources/report.pdf) (portuguese only).

## 1. Problem description

The problem being addressed in this solution relates to employee hiring: an imaginary company needs several employees during a work day, which can be of two types:
* Fulltime employees: work all day, with 1 free luch hour. May work on their lunch hour for a bonus;
* Part-time employees: work 3 hours, with no lunch hour May work an extra hour for a bonus.

The number of employees working in their lunch hour or working extra hours are limited by the Workers Union. The number of part-time employees is limited by number and ratio when compared to the number of fulltime employees.

**An optimal solution to this problem is the employee configuration that costs less (in terms of salaries to pay) to the company.**

## 2. Problem definition in Prolog

The files "probEx.pl", "probMedium.pl", "probBig.pl" and "probBig2.pl" contrain instances of the problem defined in Prolog.

The predicates that define an instance of a problem are defined as follows:

| Predicates                 | Meaning                                                                        |
|----------------------------|--------------------------------------------------------------------------------|
| input_slots                | Number of employees needed on each work hour                                   |
| input_startWork            | First working hour                                                             |
| input_endWork              | Last working hour                                                              |
| input_maxExtraWorkers      | Maximum number of workers working in their lunch hour or doing an extra hour   |
| input_fullSalaryPerHour    | Fulltime worker salary (per hour)                                              |
| input_fullBonus            | Fulltime bonus for working in lunch hour                                       |
| input_lunchHourList        | Lunch hours                                                                    |
| input_partialWorkHours     | Number of work hours for a part-time worker                                    |
| input_partialMaxWorkers    | Maximum number of part-time workers                                            |
| input_partialWorkersRatio  | Maximum percentage ratio of part-time workers compared to the fulltime workers |
| input_partialSalaryPerHour | Part-time worker salary (per hour)                                             |
| input_partialBonus         | Part-time bonus for working an extra hour                                      |

In order to run an instance of a problem, change the following instrution in "main.pl" - line 4:
```prolog
:- consult(probEx).
```
replacing "probEx" with the desired file.

Then load main.pl and type ```prolog schedule.```

## 3. Command line interface

![gui](https://github.com/msandim/optimization-employment-plog/raw/master/resources/solution.png)

After launching the configuration, information regarding the schedule of each employee is showed (textually and graphically), along with the timetable.
