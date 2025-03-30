import 'package:star/errors/errors.dart';
import 'package:star/lexing/lexing.dart' show Tokens;

sealed class Result<T> {
	Result<T> updateIfBad(Tokens tokens) => this;
	Result<T> fatalIfBad(Tokens tokens) => this;
	Result<T> fatalIfFailed() => this;
	Result<U> cast<U>() => this as Result<U>;
}

final class Success<T> extends Result<T> {
	final T made;
	final Tokens rest;

	Success(this.made, this.rest);

	Success<U> cast<U>() => Success(made as U, rest);
}

final class Failure<T> extends Result<T> {
	final Tokens begin;
	final Tokens? end;

	Failure(this.begin, this.end);
	
	Result<T> updateIfBad(Tokens tokens) => Failure(tokens, end ?? begin);
	Result<T> fatalIfBad(Tokens tokens) => Fatal(tokens, end ?? begin);
	Result<T> fatalIfFailed() => Fatal(begin, end);
	Result<U> cast<U>() => Failure(begin, end);
}

final class Fatal<T> extends Result<T> {
	final Tokens begin;
	final Tokens? end;

	Fatal(this.begin, this.end);
	
	Result<T> updateIfBad(Tokens tokens) => end != null ? this : Fatal(tokens, begin);
	Result<T> fatalIfBad(Tokens tokens) => end != null ? this : Fatal(tokens, begin);
	Result<U> cast<U>() => Fatal(begin, end);
}

final class EndOfInput<T> extends Result<T> {
	final Tokens begin;

	EndOfInput(this.begin);

	Result<U> cast<U>() => EndOfInput(begin);
}

final class FatalError<T> extends Result<T> {
	final StarError error;

	FatalError(this.error);

	Result<U> cast<U>() => FatalError(error);
}