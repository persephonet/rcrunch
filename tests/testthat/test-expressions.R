context("Expressions")

test_that(".dispatchFilter uses right numeric function", {
    ## Use expect_output because toJSON returns class "json" but prints correctly
    expect_fixed_output(toJSON(.dispatchFilter(5)),
        paste0('{"function":"==","args":[{"function":"row",',
        '"args":[]},{"value":4}]}'))
    expect_fixed_output(toJSON(.dispatchFilter(c(5, 7))),
        paste0('{"function":"in","args":[{"function":"row",',
        '"args":[]},{"column":[4,6]}]}'))
    expect_fixed_output(toJSON(.dispatchFilter(5:7)),
        paste0('{"function":"between","args":[{"function":"row",',
        '"args":[]},{"value":4},',
        '{"value":7}]}'))
})

with_mock_HTTP({
    ds <- loadDataset("test ds")

    test_that("Arithmetic generates expressions", {
        e1 <- try(ds$birthyr + 5)
        expect_is(e1, "CrunchExpr")
        zexp <- list(`function`="+",
            args=list(
                list(variable="api/datasets/1/variables/birthyr/"),
                list(value=5)
            )
        )
        expect_identical(zcl(e1), zexp)
        expect_fixed_output(e1, "Crunch expression: birthyr + 5")
        e2 <- try(5 + ds$birthyr)
        expect_is(e2, "CrunchExpr")
        expect_fixed_output(e2, "Crunch expression: 5 + birthyr")
    })

    test_that("Logic generates expressions", {
        e1 <- try(ds$birthyr < 0)
        expect_is(e1, "CrunchLogicalExpr")
        expect_fixed_output(e1, "Crunch logical expression: birthyr < 0")
    })

    test_that("R logical & CrunchLogicalExpr", {
        expect_is(c(TRUE, FALSE, TRUE) & ds$gender == "Female",
            "CrunchLogicalExpr")
        expect_is(c(TRUE, FALSE, TRUE) | ds$gender == "Female",
            "CrunchLogicalExpr")
        expect_is(ds$gender == "Female" & c(TRUE, FALSE, TRUE),
            "CrunchLogicalExpr")
        expect_is(ds$gender == "Female" | c(TRUE, FALSE, TRUE),
            "CrunchLogicalExpr")
    })

    test_that("Datetime operations: logical", {
        expect_fixed_output(ds$starttime == "2015-01-01",
            'Crunch logical expression: starttime == "2015-01-01"')
        expect_fixed_output(ds$starttime > "2015-01-01",
            'Crunch logical expression: starttime > "2015-01-01"')
        expect_fixed_output(ds$starttime == as.Date("2015-01-01"),
            'Crunch logical expression: starttime == "2015-01-01"')
        expect_fixed_output(ds$starttime > as.Date("2015-01-01"),
            'Crunch logical expression: starttime > "2015-01-01"')
    })

    test_that("Logical expr with categoricals", {
        expect_is(ds$gender == "Male", "CrunchLogicalExpr")
        expect_fixed_output(ds$gender == "Male",
            'Crunch logical expression: gender == "Male"')
        expect_fixed_output(ds$gender == as.factor("Male"),
            'Crunch logical expression: gender == "Male"')
        expect_fixed_output(ds$gender %in% "Male",
            'Crunch logical expression: gender == "Male"')
        expect_fixed_output(ds$gender %in% as.factor("Male"),
            'Crunch logical expression: gender == "Male"')
        expect_fixed_output(ds$gender %in% c("Male", "Female"),
            'Crunch logical expression: gender %in% c("Male", "Female")')
        expect_fixed_output(ds$gender %in% as.factor(c("Male", "Female")),
            'Crunch logical expression: gender %in% c("Male", "Female")')
        expect_fixed_output(ds$gender != "Female",
            'Crunch logical expression: gender != "Female"')
        expect_fixed_output(ds$gender != as.factor("Female"),
            'Crunch logical expression: gender != "Female"')
    })
    test_that("Referencing category names that don't exist warns and drops", {
        expect_warning(
            expect_fixed_output(ds$gender == "other",
                'Crunch logical expression: gender %in% character(0)'),
            paste("Category not found:", dQuote("other")))
        expect_warning(
            expect_fixed_output(ds$gender %in% c("other", "Male", "another"),
                'Crunch logical expression: gender == "Male"'),
            paste("Categories not found:", dQuote("other"), "and",
                dQuote("another")))
        expect_warning(
            expect_fixed_output(ds$gender != "other",
                'Crunch logical expression: !gender %in% character(0)'),
            paste("Category not found:", dQuote("other")))
    })

    test_that("Show method for logical expressions", {
        expect_fixed_output(ds$gender %in% c("Male", "Female"),
            'Crunch logical expression: gender %in% c("Male", "Female"')
        expect_fixed_output(ds$gender %in% 1:2,
            'Crunch logical expression: gender %in% c("Male", "Female"')
        expect_fixed_output(ds$birthyr == 1945 | ds$birthyr < 1941,
            'birthyr == 1945 | birthyr < 1941')
        expect_fixed_output(ds$gender %in% "Male" & !is.na(ds$birthyr),
            'gender == "Male" & !is.na(birthyr)')
        expect_fixed_output(!(ds$gender == "Male"),
            'Crunch logical expression: !gender == "Male"')
            ## TODO: better parentheses for ^^
        expect_fixed_output(duplicated(ds$gender),
            'Crunch logical expression: duplicated(gender)')
        expect_fixed_output(duplicated(ds$gender == "Male"),
            'Crunch logical expression: duplicated(gender == "Male")')
    })

    test_that("Can subset a CrunchExpr with R values", {
        age <- 2016 - ds$birthyr
        ## Note: no check for correct number of rows
        expect_is(age[c(TRUE, FALSE, TRUE)], "CrunchExpr")
        expect_fixed_output(toJSON(activeFilter(age[c(TRUE, FALSE, TRUE)])),
            paste0('{"function":"in","args":[{"function":"row",',
            '"args":[]},{"column":[0,2]}]}'))
        expect_is(age[c(1, 3)], "CrunchExpr")
        expect_fixed_output(toJSON(activeFilter(age[c(1, 3)])),
            paste0('{"function":"in","args":[{"function":"row",',
            '"args":[]},{"column":[0,2]}]}'))
    })

    test_that("Show method for expresssions", {
        skip("TODO: something intelligent with parentheses and order of operations")
        print(ds$birthyr * 3 + 5)
        print(3 * (ds$birthyr + 5))
    })
})

with_test_authentication({
    ds <- newDataset(df)
    ds$q1 <- factor(rep(c("selected", "not selected"), 10))
    test_that("Arithmetic expressions evaluate", {
        e1 <- try(ds$v3 + 5)
        expect_is(e1, "CrunchExpr")
        e2 <- try(5 + ds$v3)
        expect_is(e2, "CrunchExpr")
        expect_identical(as.vector(e1), as.vector(ds$v3) + 5)
        expect_identical(as.vector(e1), as.vector(e2))
        expect_identical(as.vector(ds$v3 * ds$v3), df$v3^2)
    })

    uncached({
        with_mock(`crunch::.crunchPageSize`=function (x) 5L, {
            with(temp.option(httpcache.log=""), {
                avlog <- capture.output(v35 <- as.vector(ds$v3 + 5))
            })
            test_that("as.vector with CrunchExpr is paginated", {
                logdf <- loadLogfile(textConnection(avlog))
                ## GET /values/ 4x
                ## to get data, then a 5th GET /values/ that returns 0
                ## values, which breaks the pagination loop
                expect_identical(logdf$verb, rep("GET", 5))
                expect_identical(grep("table", logdf$url), 1:5)
            })
            test_that("getValues returns the same result when paginated", {
                expect_equivalent(v35, df$v3 + 5)
            })
        })
    })

    test_that("Logical expressions evaluate", {
        e1 <- try(ds$v3 > 10)
        expect_is(e1, "CrunchLogicalExpr")
        skip("which isn't implemented correctly yet")
        expect_identical(which(e1), which(df$v3 > 10))
        skip("select with logical expression not supported")
        expect_identical(as.vector(e1), as.vector(ds$v3) > 10)
    })

    test_that("R & Crunch logical together", {
        e1 <- ds$v3 < 10 | c(rep(FALSE, 15), rep(TRUE, 5))
        expect_equivalent(as.vector(ds$v3[e1]),
            c(8, 9, 23, 24, 25, 26, 27))
        e2 <- TRUE & is.na(ds$v2)
        expect_equivalent(as.vector(ds$v3[e2]),
            23:27)
        e3 <- df$v4 == "B" & is.na(ds$v1) ## Note df
        expect_equivalent(as.vector(ds$v3[e3]),
            c(8, 10, 12))
    })

    test_that("expressions on expresssions evaluate", {
        e3 <- try(ds$v3 + ds$v3 + 10)
        expect_is(e3, "CrunchExpr")
        expect_fixed_output(e3, "Crunch expression: v3 + v3 + 10")
        expect_identical(as.vector(e3), 2*df$v3 + 10)
        e4 <- try(ds$v3 + ds$v3 * 2)
        expect_is(e4, "CrunchExpr")
        expect_fixed_output(e4, "Crunch expression: v3 + v3 * 2")
        expect_identical(as.vector(e4), 3*df$v3)
    })

    varnames <- names(df[-6])
    test_that("Select values with Numeric inequality filter", {
        e5 <- try(ds$v3[ds$v3 < 10])
        expect_is(e5, "CrunchVariable")
        expect_identical(as.vector(e5), c(8, 9))
        for (i in varnames) {
            expect_equivalent(as.vector(ds[[i]][ds$v3 < 10]),
                df[[i]][1:2], info=i)
        }
    })
    test_that("Select values with %in% on Numeric", {
        for (i in varnames) {
            expect_equivalent(as.vector(ds[[i]][ds$v3 %in% 10]),
                df[[i]][3], info=i)
            expect_equivalent(as.vector(ds[[i]][ds$v3 %in% c(10, 12)]),
                df[[i]][c(3, 5)], info=i)
        }
    })
    test_that("Select values with %in% on Categorical", {
        expect_length(as.vector(ds$v3[ds$v4 %in% "B"]), 10)
        for (i in varnames) {
            expect_equivalent(as.vector(ds[[i]][ds$v4 %in% "B"]),
                df[[i]][df$v4 %in% "B"], info=i)
        }
        expect_length(as.vector(ds$v3[ds$q1 %in% "selected"]), 10)
    })
    test_that("Select values with %in% on nonexistent categories", {
        expect_length(as.vector(ds$v3[ds$v4 %in% numeric(0)]), 0)
        expect_length(as.vector(ds$v3[!(ds$v4 %in% numeric(0))]), 20)
        expect_warning(
            expect_length(as.vector(ds$v3[ds$v4 == "other"]), 0),
            paste0("Category not found: ", dQuote("other"), ". Dropping."))
        expect_warning(
            expect_length(as.vector(ds$v3[ds$v4 != "other"]), 20),
            paste0("Category not found: ", dQuote("other"), ". Dropping."))
    })

    uncached({
        with_mock(`crunch::.crunchPageSize`=function (x) 5L, {
            with(temp.option(httpcache.log=""), {
                avlog <- capture.output(v3.5 <- as.vector(ds$v3[ds$v4 %in% "B"]))
            })
            test_that("Select values with %in% on Categorical, paginated", {
                logdf <- loadLogfile(textConnection(avlog))
                ## GET v3 entity to get /values/ URL,
                ## GET v3 entity to get categories to construct expr,
                ## GET /values/ 2x to get data,
                ## then a 3rd GET /values/ that returns 0
                ## values, which breaks the pagination loop
                expect_identical(logdf$verb, rep("GET", 5))
                expect_identical(grep("values", logdf$url), 3:5)
                expect_equivalent(v3.5, df$v3[df$v4 %in% "B"])
            })
        })
    })
    test_that("Select values with &ed filter", {
        expect_equivalent(as.vector(ds$v3[ds$v3 >= 10 & ds$v3 < 13]),
            10:12)
        f <- ds$v3 >= 10 & ds$v3 < 13
        expect_is(f, "CrunchLogicalExpr")
        for (i in varnames) {
            expect_equivalent(as.vector(ds[[i]][f]),
                df[[i]][3:5], info=i)
        }
    })
    test_that("Select values with negated filter", {
        expect_equivalent(as.vector(ds$v3[!(ds$v4 %in% "B")]),
            df$v3[df$v4 %in% "C"])
        for (i in varnames) {
            expect_equivalent(as.vector(ds[[i]][!(ds$v4 %in% "B")]),
                df[[i]][df$v4 %in% "C"], info=i)
        }
    })

    test_that("R numeric filter evaluates", {
        expect_equivalent(as.vector(ds$v3[6]), df$v3[6])
    })
    test_that("If R numeric filter is a range, 'between' is correct", {
        expect_equivalent(as.vector(ds$v3[3:18]), df$v3[3:18])
    })
    test_that("R logical filter evaluates", {
        expect_identical(as.vector(ds$v3[df$v3 < 10]), c(8, 9))
    })

    test_that("filtered categorical returns factor", {
        expect_equivalent(as.vector(ds$v4[ds$v4 == "B"]),
            factor(rep("B", 10)))
    })

    test_that("duplicated method", {
        expect_identical(which(duplicated(ds$v3)), integer(0))
        expect_equivalent(as.vector(ds$v3[duplicated(ds$v4)]), 10:27)
        expect_identical(which(duplicated(ds$v3 + 4)), integer(0))
        skip("'which' isn't implemented correctly")
        expect_identical(which(duplicated(ds$v4)), 3:20)
    })
})
