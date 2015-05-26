context("Variables")

test_that("Subclass constructor selector", {
    expect_equivalent(class(pickSubclassConstructor("numeric")), 
        "classGeneratorFunction")
    expect_identical(pickSubclassConstructor("numeric"), NumericVariable)
    expect_identical(pickSubclassConstructor("categorical"),
        CategoricalVariable)
    expect_identical(pickSubclassConstructor("text"), TextVariable)
    expect_identical(pickSubclassConstructor("datetime"), DatetimeVariable)
    expect_identical(pickSubclassConstructor("multiple_response"),
        MultipleResponseVariable)
    expect_identical(pickSubclassConstructor(), CrunchVariable)
    expect_identical(pickSubclassConstructor("foo"), CrunchVariable)
})

with(fake.HTTP, {
    ds <- loadDataset("test ds")
    
    test_that("Variable init, as, is", {
        expect_true(is.variable(ds[[1]]))
        expect_true(all(vapply(ds, is.variable, logical(1))))
        expect_false(is.variable(5))
        expect_false(is.variable(NULL))
    })
    
    test_that("Variable subclass definitions, is", {
        expect_true(is.dataset(ds))
        expect_true(is.Categorical(ds$gender))
        expect_true(is.Numeric(ds$birthyr))
        expect_true(is.Text(ds[["textVar"]]))
        expect_true(is.Datetime(ds$starttime))
        expect_true(is.Multiple(ds$mymrset))
        expect_true(is.Array(ds$mymrset))
        expect_false(is.CA(ds$mymrset))
    })
    
    test_that("Categories for categorical", {
        thisone <- categories(ds$gender)
        expect_true(is.categories(thisone))
        expect_identical(length(thisone), 3L)
        expect_true(is.category(thisone[[1]]))
    })
    test_that("Categories for noncategorical", {
        expect_identical(categories(ds$birthyr), NULL)
    })
    
    test_that("Variable metadata retrieved from tuples", {
        expect_identical(name(ds$gender), "Gender")
        expect_identical(description(ds$starttime), "Interview Start Time")
        expect_identical(alias(ds$gender), "gender")
    })
    
    test_that("Variable setters (mock)", {
        tp <- tuple(ds$gender)@body
        tp$name <- "Sex"
        mock.tuple <- structure(list(tp), .Names=self(ds$gender))
        expect_error(name(ds$gender) <- "Sex",
            paste("PATCH", self(variables(ds)), toJSON(mock.tuple)),
            fixed=TRUE)
    })
    
    test_that("Variable setters don't hit server if data not changed", {
        expect_that(name(ds$gender) <- "Gender",
            does_not_throw_error())
    })
    
    test_that("refresh", {
        expect_identical(ds$gender, refresh(ds$gender))
    })
})

if (run.integration.tests) {
    with(test.authentication, {
        with(test.dataset(df), {
            test_that("can delete variables", {
                expect_true("v1" %in% names(ds))
                d <- try(delete(ds$v1))
                expect_false(is.error(d))
                expect_false("v1" %in% names(refresh(ds)))
            })
        })
        
        with(test.dataset(df), {
            test_that("before modifying", {
                expect_identical(name(ds$v1), "v1")
                expect_identical(description(ds$v2), "")
                expect_identical(alias(ds$v1), "v1")
            })
            name(ds$v1) <- "Variable 1"
            description(ds$v2) <- "Description 2"
            alias(ds$v1) <- "var1"
            test_that("can modify name, description, alias on var in dataset", {
                expect_true(is.null(ds$v1))
                expect_identical(name(ds$var1), "Variable 1")
                expect_identical(alias(ds$var1), "var1")
                expect_identical(description(ds$v2), "Description 2")
                ds <- refresh(ds)
                expect_true(is.null(ds$v1))
                expect_identical(name(ds$var1), "Variable 1")
                expect_identical(description(ds$v2), "Description 2")
            })
        })
        with(test.dataset(df), {
            v1 <- ds$v1
            name(v1) <- "alt"
            description(v1) <- "asdf"
            alias(v1) <- "Alias!"
            test_that("can modify name, description, alias on var object", {
                expect_identical(name(v1), "alt")
                expect_identical(description(v1), "asdf")
                expect_identical(alias(v1), "Alias!")
                v1 <- refresh(v1)
                expect_identical(name(v1), "alt")
                expect_identical(description(v1), "asdf")
                expect_identical(alias(v1), "Alias!")
            })
        })
        
        with(test.dataset(mrdf), {
            ds <- mrdf.setup(ds)
            test_that("before modifying", {
                expect_identical(name(ds$CA), "CA")
                expect_identical(description(ds$CA), "")
                expect_identical(alias(ds$CA), "CA")
            })
            name(ds$CA) <- "Variable 1"
            description(ds$CA) <- "Description 1"
            alias(ds$CA) <- "var1"
            test_that("can modify name, description, alias on var in dataset", {
                expect_true(is.null(ds$CA))
                expect_identical(name(ds$var1), "Variable 1")
                expect_identical(alias(ds$var1), "var1")
                expect_identical(description(ds$var1), "Description 1")
                ds <- refresh(ds)
                expect_true(is.null(ds$CA))
                expect_identical(name(ds$var1), "Variable 1")
                expect_identical(description(ds$var1), "Description 1")
            })
        })
    })
}