module basic_address::workout_dapp {
    //use std::table;
    use std::signer;
    //use std::random;
    use std::vector;
    use std::debug;
    use std::string::{String,utf8};
    use aptos_framework::randomness;

    struct ExercisesList has key {
        exercises: vector<Exercise>,
    }

    struct Exercise has copy, store {
        name: vector<u8>,
        description: vector<u8>
    }

    struct Profile has key {
        exercises_completed: vector<Exercise>,
        total_workouts: u64,
    }

    fun init_module(account: &signer) {
        let profile = Profile {
          exercises_completed: vector::empty<Exercise>(),
          total_workouts: 0,
        };
        move_to(account, profile);

        let exercises = vector::empty<Exercise>();
        vector::push_back(&mut exercises, Exercise { name: b"Push-Ups", description: b"Do push-ups" });
        vector::push_back(&mut exercises, Exercise { name: b"Squats", description: b"Do squats" });
        vector::push_back(&mut exercises, Exercise { name: b"Running", description: b"Run for 10 minutes" });
        vector::push_back(&mut exercises, Exercise { name: b"Cycling", description: b"Cycle for 5 km" });
        vector::push_back(&mut exercises, Exercise { name: b"Plank", description: b"Hold plank position" });
        vector::push_back(&mut exercises, Exercise { name: b"Jumping Jacks", description: b"Do jumping jacks" });
        vector::push_back(&mut exercises, Exercise { name: b"Burpees", description: b"Do burpees" });

        let list = ExercisesList { exercises };
        move_to(account, list);
    }

    fun entry(account: &signer, index: u64) acquires ExercisesList, Profile{
        let account_address = signer::address_of(account);
        let repository = borrow_global<ExercisesList>(account_address);
        let exercise = *vector::borrow(&repository.exercises, index);

        if (exists<Profile>(account_address)) {
            let profile = borrow_global_mut<Profile>(account_address);
            profile.total_workouts = profile.total_workouts + 1;
            vector::push_back(&mut profile.exercises_completed, exercise);
        } else {
            let profile = Profile {
              exercises_completed: vector::empty<Exercise>(),
              total_workouts: 0,
            };
            vector::push_back(&mut profile.exercises_completed, exercise);
            move_to(account, profile);
        };
    }

    #[view]
    public fun get_exercises_list_count(account: address): u64 acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        vector::length(&repository.exercises)
    }

    #[view]
    public fun get_exercise_name_by_index(account: address, index: u64): vector<u8> acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercise = vector::borrow(&repository.exercises, index);
        exercise.name
    }

    #[view]
    public fun get_exercise(account: address, index: u64): Exercise acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercise = *vector::borrow(&repository.exercises, index);
        exercise
    }

    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_random_exercise(account: address): vector<u8> acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let len = vector::length(&repository.exercises);

        let index = get_random_number(len);

        let exercise = vector::borrow(&repository.exercises, index);
        exercise.name
    }

    fun get_random_number(length: u64): u64 {
        randomness::u64_range(0, length)
    }

    #[test(account = @0x1)]
    public fun test_init(account: signer) {
        init_module(&account);
    }

    #[test(account = @0x1)]
    public fun test_length(account: signer) acquires ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 7, 1);

        let name = get_exercise_name_by_index(account_address, 0);
        assert!(vector::equals(&name, b"Push-Ups"), 2);
    }

    #[test(account = @0x1)]
    public fun test_random_exercise(account: signer) acquires ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);

        let exercise = get_random_exercise(account_address);
    }
}
